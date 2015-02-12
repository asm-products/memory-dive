
    expect = (require 'chai').expect
    _ = require 'lodash'

    compound = null
    worker = null
    User = null
    EvernoteObject = null

    # Read environment variables required by the test
    parseEnvInt = (env) -> env and parseInt(env)
    testToken = process.env.MEMORY_DIVE_TEST_FACEBOOK_TOKEN
    testUserId = process.env.MEMORY_DIVE_TEST_FACEBOOK_USER_ID
    testUserName = process.env.MEMORY_DIVE_TEST_FACEBOOK_USER_NAME
    testEvernoteToken = process.env.MEMORY_DIVE_TEST_EVERNOTE_TOKEN
    testMinExpectedNotes = parseEnvInt(process.env.MEMORY_DIVE_TEST_EVERNOTE_MIN_EXPECTED_NOTES)

    # Skip tests in the test suite unless all environment variables are present
    DO_TESTS = testToken and testUserId and testUserName and testEvernoteToken and testMinExpectedNotes

    describe 'evernoteWorker module', ->
        this.timeout 600000

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
            EvernoteObject = compound.models.EvernoteObject
            expect(EvernoteObject).to.exist
            worker = compound.workers.evernote
            expect(worker).to.exist
            # When *not* recording we suppress throttling when running tests so that the tests are fast.
            compound.suppressThrottling = (process.env.NOCK_RECORDING != '1')
            done()

        testUser = null
        userProviderData = null

Before each test we clean the db and create a new user doc.

        beforeEach (done) ->

We define the user data with all the properties necessary for correct collection and persistence.

            userData =
                facebookId: testUserId
                token:  testToken
                profile:
                    username: testUserName
                utcOffset:  1 * 60 * 60 * 1000  #   UTC+1

            nocks = compound.startNocking 'workers__data__evernoteWorker.beforeEach.json'

            compound.consistencyTimeout ->
                compound.couch.cleanDb (err) ->
                    return done err if err

                    User.findOrCreate userData, (err, dbUser) ->
                        expect(err).to.not.exist
                        expect(dbUser).to.exist
                        testUser = dbUser
                        #compound.nocksDone nocks

                        userProviderData =
                            userId: dbUser.id
                            providerId: compound.common.constants.providerId.EVERNOTE
                            providerData:
                                token:  testEvernoteToken

                        compound.stopNocking nocks
                        done()

        it 'updateNotes puts all notes', DO_TESTS and (done) ->
            nocks = compound.startNocking 'workers__data__evernoteWorker.1.json'

            compound.consistencyTimeout ->
                EvernoteObject.all (err, items) ->
                    return done err if err
                    expect(items).to.exist
                    expect(items).to.be.empty

                    worker.updateNotes undefined, userProviderData, (err) ->
                        return done err if err

                        compound.consistencyTimeout ->
                            EvernoteObject.all (err, items) ->
                                return done err if err

                                expect(items).to.exist
                                expect(items).to.have.length.of.at.least(testMinExpectedNotes)
                                expect(_.all items, (item) ->
                                    item.userId is userProviderData.userId
                                ).to.be.true
                                compound.stopNocking nocks
                                done()
