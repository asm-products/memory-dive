
    expect = (require 'chai').expect
    _ = require 'lodash'

    compound = null
    worker = null
    User = null
    TwitterObject = null

    # Read environment variables required by the test
    parseEnvInt = (env) -> env and parseInt(env)
    testToken = process.env.MEMORY_DIVE_TEST_FACEBOOK_TOKEN
    testUserId = process.env.MEMORY_DIVE_TEST_FACEBOOK_USER_ID
    testUserName = process.env.MEMORY_DIVE_TEST_FACEBOOK_USER_NAME
    testTwitterToken = process.env.MEMORY_DIVE_TEST_TWITTER_TOKEN
    testTwitterTokenSecret = process.env.MEMORY_DIVE_TEST_TWITTER_TOKEN_SECRET
    testTwitterUserId = process.env.MEMORY_DIVE_TEST_TWITTER_USER_ID
    testMinExpectedTweets = parseEnvInt(process.env.MEMORY_DIVE_TEST_TWITTER_MIN_EXPECTED_TWEETS)

    # Skip tests in the test suite unless all environment variables are present
    DO_TESTS = testToken and testUserId and testUserName and testTwitterToken and testTwitterTokenSecret and testTwitterUserId and testMinExpectedTweets

    describe 'twitterWorker module', ->
        this.timeout 600000

        init = (done) ->
            User = compound.models.User
            expect(User).to.exist
            TwitterObject = compound.models.TwitterObject
            expect(TwitterObject).to.exist
            worker = compound.workers.twitter
            expect(worker).to.exist
            done()

        DO_TESTS and before (done) ->
            compound = getCompound()
            expect(compound).to.exist
            if compound.memoryDiveReady
                return init done
            compound.on 'memoryDiveReady', ->
                return init done

        it 'updateUserStatuses puts all statuses into db', DO_TESTS and (done) ->
            nocks = compound.startNocking 'workers__data__twitterWorker.1.json'

            userData =
                facebookId: testUserId
                token:  testToken
                profile:
                    username: testUserName
                utcOffset:  1 * 60 * 60 * 1000  #   UTC+1

            compound.consistencyTimeout ->
                compound.couch.cleanDb (err) ->
                    return done err if err

                    User.findOrCreate userData, (err, dbUser) ->
                        expect(err).to.not.exist
                        expect(dbUser).to.exist

                        # When *not* recording we suppress throttling when running tests so that the tests are fast.
                        compound.twitterSuppressThrottling = (process.env.NOCK_RECORDING != '1')

                        providerData =
                            userId: dbUser.id
                            providerId: compound.common.constants.providerId.TWITTER
                            providerUserId: testTwitterUserId
                            providerData:
                                token:          testTwitterToken
                                tokenSecret:    testTwitterTokenSecret

                        compound.consistencyTimeout ->
                            TwitterObject.all (err, items) ->
                                return done err if err
                                expect(items).to.exist
                                expect(items).to.be.empty

                                worker.updateUserStatuses undefined, providerData, (err) ->
                                    return done err if err

                                    compound.consistencyTimeout ->
                                        TwitterObject.all (err, items) ->
                                            compound.stopNocking nocks
                                            return done err if err

                                            expect(items).to.exist
                                            expect(items).to.have.length.of.at.least(testMinExpectedTweets)
                                            expect(_.all items, (item) ->
                                                item.type == 'status' and item.utcOffset == userData.utcOffset
                                            ).to.be.true
                                            done()
