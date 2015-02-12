
expect = (require 'chai').expect
_ = require 'lodash'

compound = null
User = null
testedUser = null

# Read environment variables required by the test
parseEnvInt = (env) -> env and parseInt(env)
testToken = process.env.MEMORY_DIVE_TEST_FACEBOOK_TOKEN
testUserId = process.env.MEMORY_DIVE_TEST_FACEBOOK_USER_ID
testUserName = process.env.MEMORY_DIVE_TEST_FACEBOOK_USER_NAME

# Skip tests in the test suite unless all environment variables are present
DO_TESTS = testToken and testUserId and testUserName

userData =
    facebookId: testUserId
    token:  testToken
    profile:
        username: testUserName

providerData = null

describe 'User model', ->
    this.timeout 60000

    DO_TESTS and before (done) ->
        compound = getCompound()
        expect(compound).to.exist
        if compound.memoryDiveReady
            return init done
        compound.on 'memoryDiveReady', ->
            return init done

    init = (done) ->
        User = compound.models.User
        expect(User).to.exist

        nocks = compound.startNocking 'models__data__user.before.json'

        # We clean the entire db and then create a test user doc and *object*.
        # We use this object in tests that assume correct creation of user docs
        # as then we don't have to screw with timestamp|createdOn interception.
        compound.couch.cleanDb (err) ->
            return done err if err

            User.findOrCreate userData, (err, dbUser) ->
                expect(err).to.not.exist
                expect(dbUser).to.exist
                expect(dbUser).to.be.an 'Object'
                expect(dbUser).to.have.property 'username'
                expect(dbUser).to.have.property 'facebookToken'
                expect(dbUser).to.have.property 'createdOn'
                expect(dbUser).to.have.property 'timestamp'
                testedUser = dbUser
                providerData =
                    _id:    'testProviderId'
                    userId: testedUser.id
                    providerId: compound.common.constants.providerId.FACEBOOK
                    providerUserId: testUserId
                    providerData:
                        token:  testToken
                compound.stopNocking nocks
                done()

    beforeEach (done) ->
        nocks = compound.startNocking 'models__data__user.beforeEach.json'
        compound.couch.cleanDb (err) ->
            return done err if err
            compound.stopNocking nocks
            done()

    it 'ensures that facebookId is a string', DO_TESTS and (done) ->
        nocks = compound.startNocking 'models__data__user.1.json'

        badUserData =
            facebookId: 12345
        User.findOrCreate badUserData, (err, dbUser) ->
            expect(err).to.exist
            expect(err).to.be.an 'Object'
            expect(err.message).to.equal 'invalid facebookId'
            expect(dbUser).to.not.exist
            compound.stopNocking nocks
            done()

    it 'findOrCreate creates a new User and subsequently finds the same one', DO_TESTS and (done) ->
        nocks = compound.startNocking 'models__data__user.2.json'

        User.findOrCreate userData, (err, dbUser) ->
            expect(err).to.not.exist
            expect(dbUser).to.exist
            expect(dbUser).to.be.an 'Object'
            expect(dbUser).to.have.property 'username'
            expect(dbUser).to.have.property 'facebookToken'
            expect(dbUser).to.have.property 'createdOn'
            expect(dbUser).to.have.property 'timestamp'
            # We didn't define utcOffset...
            expect(dbUser).to.not.have.property 'utcOffset'
            # ...but it's still correctly 0.
            expect(dbUser.getUtcOffset()).to.be.equal 0

            User.findOrCreate userData, (err, dbUser2) ->
                expect(err).to.not.exist
                expect(dbUser2).to.exist
                expect(dbUser2.id).to.be.equal dbUser.id
                compound.stopNocking nocks
                done()

    it 'save() updates the doc', DO_TESTS and (done) ->
        nocks = compound.startNocking 'models__data__user.3.json'

        User.findOrCreate userData, (err, dbUser) ->
            expect(err).to.not.exist
            expect(dbUser).to.exist
            rev = dbUser._rev
            dbUser.save (err) ->
                return done err if err
                # We don't test timestamp as those are always hard-coded to 0 for testing.
                # See comments on it in User model module.
                expect(dbUser._rev).to.not.equal rev
                compound.stopNocking nocks
                done()

    describe 'on post', ->
        it 'returns error for invalid data', DO_TESTS and (done) ->
            nocks = compound.startNocking 'models__data__user.14.json'

            testedUser.post {}, (error, data) ->
                expect(error).to.exist
                expect(error).to.equal 'Invalid POST data.'
                expect(data).to.be.undefined
                compound.stopNocking nocks
                done()

        it 'returns error for invalid rev data', DO_TESTS and (done) ->
            nocks = compound.startNocking 'models__data__user.15.json'

            badPostData =
                rev: '123'

            testedUser.post badPostData, (err) ->
                expect(err).to.exist
                expect(err.indexOf('Invalid rev data')).to.equal 0
                compound.stopNocking nocks
                done()

        it 'doesn\'t update unless there are actual changes', DO_TESTS and (done) ->
            nocks = compound.startNocking 'models__data__user.16.json'

            User.findOrCreate userData, (err, dbUser) ->
                return done err if err
                expect(dbUser).to.exist

                postData =
                    rev: dbUser._rev

                dbUser.post postData, (err) ->
                    expect(err).to.not.exist
                    expect(dbUser._rev).to.equal postData.rev
                    compound.stopNocking nocks
                    done()

        it 'makes an update when there are actual changes', DO_TESTS and (done) ->
            nocks = compound.startNocking 'models__data__user.17.json'

            User.findOrCreate userData, (err, dbUser) ->
                return done err if err
                expect(dbUser).to.exist

                postData =
                    rev: dbUser._rev
                    timezone: 'something completely different'

                expect(dbUser.timezone).to.not.equal postData.timezone

                dbUser.post postData, (err) ->
                    expect(err).to.not.exist
                    expect(dbUser._rev).to.not.equal postData.rev
                    expect(dbUser.timezone).to.equal postData.timezone
                    compound.stopNocking nocks
                    done()
