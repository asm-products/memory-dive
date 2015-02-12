    expect = (require 'chai').expect
    _ = require 'lodash'

    compound = null
    User = null
    testUser = null
    SlackObject = null
    slackWorker = null
    FoursquareObject = null
    foursquareWorker = null

    # Read environment variables required by the test
    parseEnvInt = (env) -> env and parseInt(env)
    testToken = process.env.MEMORY_DIVE_TEST_FACEBOOK_TOKEN
    testUserId = process.env.MEMORY_DIVE_TEST_FACEBOOK_USER_ID
    testUserName = process.env.MEMORY_DIVE_TEST_FACEBOOK_USER_NAME
    testSlackToken = process.env.MEMORY_DIVE_TEST_SLACK_TOKEN
    testSlackTeamId = process.env.MEMORY_DIVE_TEST_SLACK_TEAM_ID
    testSlackUserId = process.env.MEMORY_DIVE_TEST_SLACK_USER_ID
    testSlackMinExpectedMessages = parseEnvInt(process.env.MEMORY_DIVE_TEST_SLACK_MIN_EXPECTED_MESSAGES)
    testFoursquareToken = process.env.MEMORY_DIVE_TEST_FOURSQUARE_TOKEN
    testFoursquareMinExpectedCheckIns = parseEnvInt(process.env.MEMORY_DIVE_TEST_FOURSQUARE_MIN_EXPECTED_CHECK_INS)

    # Skip tests in the test suite unless all environment variables are present
    DO_TESTS = testToken and testUserId and testUserName and testSlackToken and testSlackTeamId and testSlackUserId and testSlackMinExpectedMessages and testFoursquareToken and testFoursquareMinExpectedCheckIns

    describe 'genericWorker module', ->
        this.timeout 600000
        init = (done) ->
            User = compound.models.User
            expect(User).to.exist
            SlackObject = compound.models.SlackObject
            expect(SlackObject).to.exist
            FoursquareObject = compound.models.FoursquareObject
            expect(FoursquareObject).to.exist
            slackWorker = compound.workers.slack
            expect(slackWorker).to.exist
            foursquareWorker = compound.workers.foursquare
            expect(foursquareWorker).to.exist

            userData =
                facebookId: testUserId
                token:  testToken
                profile:
                    username: testUserName
                utcOffset: 1 * 60 * 60 * 1000   #   UTC+1

Because we are using timestamps for createdOn and timestamp fields we have to replaces their values in the body with the value specified in the nock JSON.

            nocks = compound.startNocking 'workers__data__genericWorker.before.json'

            # We clean the entire db and then create a test user doc and *object*.
            # We use this object in tests that assume correct creation of user docs
            # as then we don't have to screw with timestamp|createdOn interception.
            compound.couch.cleanDb (err) ->
                return done err if err

                User.findOrCreate userData, (err, dbUser) ->
                    expect(err).to.not.exist
                    expect(dbUser).to.exist
                    testUser = dbUser
                    compound.stopNocking nocks
                    done()

        DO_TESTS and before (done) ->
            compound = getCompound()
            expect(compound).to.exist
            if compound.memoryDiveReady
                return init done
            compound.on 'memoryDiveReady', ->
                return init done

        DO_TESTS and beforeEach (done) ->
            nocks = compound.startNocking 'workers__data__genericWorker.beforeEach.json'
            compound.consistencyTimeout ->
                compound.cleanDbExceptDesignAndUser (err) ->
                    return done err if err
                    compound.stopNocking nocks
                    done()

        it 'slackWorker.updateMessages puts all messages into db', DO_TESTS and (done) ->

            nocks = compound.startNocking 'workers__data__genericWorker.1.json'

            compound.consistencyTimeout ->
                SlackObject.all (err, items) ->
                    return done err if err
                    expect(items).to.exist
                    expect(items).to.be.empty

                    providerData =
                        _id:        'testProviderId'
                        userId:     testUser.id
                        providerId: compound.common.constants.providerId.SLACK
                        providerUserId: 12345
                        providerData:
                            token:  testSlackToken
                            teamId: testSlackTeamId
                            userId: testSlackUserId

                    slackWorker.updateMessages undefined, providerData, (err) ->
                        return done err if err

                        compound.common.bulkDataUploader.flush (err) ->
                            return done err if err

                            compound.consistencyTimeout ->
                                SlackObject.all (err, items) ->
                                    compound.stopNocking nocks
                                    return done err if err

                                    expect(items).to.exist
                                    expect(items).to.have.length.of.at.least(testSlackMinExpectedMessages)
                                    expect(_.all items, (item) ->
                                        item.providerId = providerData._id
                                    ).to.be.true
                                    done()

        it 'foursquareWorker.updateCheckIns puts all messages into db', DO_TESTS and (done) ->

            nocks = compound.startNocking 'workers__data__genericWorker.2.json'

            compound.consistencyTimeout ->
                FoursquareObject.all (err, items) ->
                    return done err if err
                    expect(items).to.exist
                    expect(items).to.be.empty

                    providerData =
                        _id:        'testProviderId'
                        userId:     testUser.id
                        providerId: compound.common.constants.providerId.FOURSQUARE
                        providerUserId: 12345
                        providerData:
                            token:  testFoursquareToken

                    foursquareWorker.updateCheckIns undefined, providerData, (err) ->
                        return done err if err

                        compound.consistencyTimeout ->
                            compound.common.bulkDataUploader.flush (err) ->
                                return done err if err

                                FoursquareObject.all (err, items) ->
                                    compound.stopNocking nocks
                                    return done err if err

                                    expect(items).to.exist
                                    expect(items).to.have.length.of.at.least(testFoursquareMinExpectedCheckIns)
                                    expect(_.all items, (item) ->
                                        item.providerId = providerData._id
                                    ).to.be.true
                                    done()
