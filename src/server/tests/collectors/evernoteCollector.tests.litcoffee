    expect = (require 'chai').expect
    _ = require 'lodash'

    compound = null
    collector = null

    collectionParams =
        suppressThrottling:     (process.env.NOCK_RECORDING != '1')

    # Read environment variables required by the test
    parseEnvInt = (env) -> env and parseInt(env)
    testToken = process.env.MEMORY_DIVE_TEST_EVERNOTE_TOKEN
    testUserId = parseEnvInt(process.env.MEMORY_DIVE_TEST_EVERNOTE_USER_ID)
    testUserName = process.env.MEMORY_DIVE_TEST_EVERNOTE_USERNAME
    testMinExpectedNotes = parseEnvInt(process.env.MEMORY_DIVE_TEST_EVERNOTE_MIN_EXPECTED_NOTES)

    # Skip tests in the test suite unless all environment variables are present
    DO_TESTS = testToken and testUserId and testUserName and testMinExpectedNotes

    describe 'evernoteCollector module', ->
        this.timeout 60000

        DO_TESTS and before (done) ->
            compound = getCompound()
            expect(compound).to.exist
            if compound.memoryDiveReady
                return init done
            compound.on 'memoryDiveReady', ->
                return init done

        providerData =
            providerData:
                token:  testToken

        init = (done) ->
            collector = compound.collectors.evernote
            expect(collector).to.exist
            done()

        describe 'has collectNotes that', ->
            it 'collects notes', DO_TESTS and (done) ->
                counter = 0

                nocks = compound.startNocking 'workers__data__evernoteCollector.1.json'

                collector.collectNotes providerData, collectionParams, (err, item, next) ->
                    return done err if err
                    if item
                        ++counter
                        return next()

                    expectAll()

                expectAll = () ->
                    compound.stopNocking nocks
                    expect(counter).to.be.at.least(testMinExpectedNotes)
                    done()

        describe 'has collectUserData that', ->
            it 'collects user data', DO_TESTS and (done) ->
                counter = 0

                nocks = compound.startNocking 'workers__data__evernoteCollector.2.json'

                collector.collectUserData providerData, (err, user) ->
                    compound.stopNocking nocks
                    return done err if err
                    expect(user).to.exist
                    expect(user.id).to.equal testUserId
                    expect(user.username).to.equal testUserName
                    done()
