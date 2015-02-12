
    expect  = (require 'chai').expect
    _       = require('lodash')
    frugal  = require 'frugal-couch'

    compound = null
    worker = null
    User = null
    FacebookObject = null
    testUser = null
    statistician = null
    userData = null
    providerData = null
    debug = (require 'debug') 'memdive::common::userDataStatistician::tests'

    # Read environment variables required by the test
    parseEnvInt = (env) -> env and parseInt(env)
    testToken = process.env.MEMORY_DIVE_TEST_FACEBOOK_TOKEN
    testUserId = process.env.MEMORY_DIVE_TEST_FACEBOOK_USER_ID
    testUserName = process.env.MEMORY_DIVE_TEST_FACEBOOK_USER_NAME

    # Skip tests in the test suite unless all environment variables are present
    DO_TESTS = testToken and testUserId and testUserName

    describe 'userDataStatistician module', ->
        this.timeout 600000

        init = (done) ->
            User = compound.models.User
            expect(User).to.exist
            FacebookObject = compound.models.FacebookObject
            expect(FacebookObject).to.exist
            worker = compound.workers.facebook
            expect(worker).to.exist
            statistician = compound.common.userDataStatistician

            userData =
                facebookId: testUserId
                token:  testToken
                profile:
                    username: testUserName
                utcOffset:  1 * 60 * 60 * 1000  #   UTC+1

            nocks = compound.startNocking 'common__data__userDataStatistician.init.json'

            compound.couch.cleanDb (err) ->
                return done err if err

                testData = JSON.parse((require 'fs').readFileSync 'src/server/tests/fixtures/userDataStatistician.test.json')

                testDocs = _(testData.rows)
                    .map('doc')
                    .filter (doc) ->
                        return doc._id.indexOf('_design') != 0
                    .value()

                debug 'prepared', testDocs.length, 'test docs'

                frugal.overwriteBulk compound.couch, testDocs, (err, res) ->
                    debug 'bulk uploaded', testDocs.length, 'test docs'

                    expect(err).to.not.exist
                    expect(_(res).filter((ret) -> return ret.error).value()).to.be.empty

                    compound.consistencyTimeout ->
                        User.findOrCreate userData, (err, dbUser) ->
                            compound.stopNocking nocks
                            expect(err).to.not.exist
                            expect(dbUser).to.exist
                            testUser = dbUser
                            done()

        DO_TESTS and before (done) ->
            compound = getCompound()
            expect(compound).to.exist
            if compound.memoryDiveReady
                return init done
            compound.on 'memoryDiveReady', ->
                return init done

        it 'returns correct test user data', DO_TESTS and (done) ->
            nocks = compound.startNocking 'common__data__userDataStatistician.1.json'
            statistician.general testUser, (err, stats) ->
                compound.stopNocking nocks
                expect(err).to.not.exist
                expect(stats).to.exist
                expect(stats).to.be.an.array
                expect(stats.length).to.equal(11)

                # This reduceds the year/month stats to total stats.
                # It works the same way our re-reduce works in CouchDb userData view.
                totals = _.reduce stats, (totals, yearMonthStats) ->
                    _(yearMonthStats).keys().each (model) ->
                        totals[model] = (totals[model] or 0) + yearMonthStats[model]
                    return totals
                delete totals.year
                delete totals.month

                expect(totals.FacebookObject).to.equal(3)
                expect(totals.TwitterObject).to.equal(5)
                expect(totals.DropboxObject).to.equal(4)
                expect(totals.count).to.equal(12)
                done()
