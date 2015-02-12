
    expect = (require 'chai').expect
    _ = require 'lodash'

    compound = null
    collector = null

    # Read environment variables required by the test
    parseEnvInt = (env) -> env and parseInt(env)
    testToken = process.env.MEMORY_DIVE_TEST_SLACK_TOKEN
    testTeamId = process.env.MEMORY_DIVE_TEST_SLACK_TEAM_ID
    testUserId = process.env.MEMORY_DIVE_TEST_SLACK_USER_ID
    testMinExpectedMessages = parseEnvInt(process.env.MEMORY_DIVE_TEST_SLACK_MIN_EXPECTED_MESSAGES)

    # Skip tests in the test suite unless all environment variables are present
    DO_TESTS = testToken and testTeamId and testUserId and testMinExpectedMessages

    describe 'slackCollector module', ->
        this.timeout 60000

        DO_TESTS and before (done) ->
            compound = getCompound()
            expect(compound).to.exist
            if compound.memoryDiveReady
                return init done
            compound.on 'memoryDiveReady', ->
                return init done

        providerData = {}

        init = (done) ->
            collector = compound.collectors.slack
            providerData =
                providerId:  compound.common.constants.providerId.SLACK
                providerData:
                    token:  testToken
                    teamId: testTeamId
                    userId: testUserId
            expect(collector).to.exist
            done()

        describe 'has collectMessages that', ->
            it 'throw if no callback is given', DO_TESTS and ->
                expect(collector.collectMessages).to.throw 'no arguments'

            it 'collects messages for correct provider data', DO_TESTS and (done) ->

                nocks = compound.startNocking 'workers__data__slackCollector.1.json'

                counter = 0
                collector.collectMessages providerData, (err, item, next) ->
                    return done err if err
                    if item
                        ++counter
                        return next()

                    expectAll()

                expectAll = () ->
                    compound.stopNocking nocks
                    expect(counter).to.be.at.least(testMinExpectedMessages)
                    done()
