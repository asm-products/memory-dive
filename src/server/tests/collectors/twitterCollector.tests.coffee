expect = (require 'chai').expect
nock   = require 'nock'

compound = null
collector = null

# Read environment variables required by the test
parseEnvInt = (env) -> env and parseInt(env)
testConsumerKey = process.env.MEMORY_DIVE_TWITTER_CONSUMER_KEY
testConsumerSecret = process.env.MEMORY_DIVE_TWITTER_CONSUMER_SECRET
testToken = process.env.MEMORY_DIVE_TEST_TWITTER_TOKEN
testTokenSecret = process.env.MEMORY_DIVE_TEST_TWITTER_TOKEN_SECRET
testUserId = process.env.MEMORY_DIVE_TEST_TWITTER_USER_ID
testMinExpectedTweets = parseEnvInt(process.env.MEMORY_DIVE_TEST_TWITTER_MIN_EXPECTED_TWEETS)

# Skip tests in the test suite unless all environment variables are present
DO_TESTS = testConsumerKey and testConsumerSecret and testToken and testTokenSecret and testUserId and testMinExpectedTweets

describe 'twitterCollector module', ->
    # Huge timeout as Twitter is both slow *and* limits the rate.
    # This test should really be run only when the entire suite is run.
    this.timeout 600000

    DO_TESTS and before (done) ->
        compound = getCompound()
        expect(compound).to.exist
        if compound.memoryDiveReady
            return init done
        compound.on 'memoryDiveReady', ->
            return init done

    providerData = null

    twitterParams =
        twitterConsumerKey:     testConsumerKey
        twitterConsumerSecret:  testConsumerSecret
        # When *not* recording we suppress throttling when running tests so that the tests are fast.
        suppressThrottling:     (process.env.NOCK_RECORDING != '1')

    init = (done) ->
        providerData =
            userId: 'ierceg'
            providerId: compound.common.constants.providerId.TWITTER
            providerUserId: testUserId
            providerData:
                token:          testToken
                tokenSecret:    testTokenSecret

        collector = compound.collectors.twitter
        expect(collector).to.exist
        done()

    describe 'has collectUserStatuses that', ->
        it 'returns error if no callback is given', DO_TESTS and ->
            err = collector.collectUserStatuses()
            expect(err).to.exist
            expect(err.message).to.equal 'Invalid input params'

        it 'returns error if user is not associated with Twitter', DO_TESTS and (done) ->
            insufficientUserData =
                username: 'ierceg'

            collector.collectUserStatuses insufficientUserData, twitterParams, (err) ->
                expect(err).to.exist
                expect(err.message).to.equal 'Provider data not validly associated with Twitter'
                done()

        it 'collects tweets for correct user data', DO_TESTS and (done) ->
            counter = 0

            nocks = compound.startNocking 'workers__data__twitterCollector.1.json'

            collector.collectUserStatuses providerData, twitterParams, (err, item, next) ->
                return done err if err
                if item
                    ++counter
                    return next() if counter < testMinExpectedTweets

                expectAll()

            expectAll = () ->
                compound.stopNocking nocks
                expect(counter).to.be.at.least(testMinExpectedTweets)
                done()
