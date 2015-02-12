
    expect = (require 'chai').expect
    _ = require 'lodash'

    compound = null
    collector = null

    # Read environment variables required by the test
    parseEnvInt = (env) -> env and parseInt(env)
    testToken = process.env.MEMORY_DIVE_TEST_FOURSQUARE_TOKEN
    testMinExpectedCheckIns = parseEnvInt(process.env.MEMORY_DIVE_TEST_FOURSQUARE_MIN_EXPECTED_CHECK_INS)

    # Skip tests in the test suite unless all environment variables are present
    DO_TESTS = testToken and testMinExpectedCheckIns

    describe 'foursquareCollector module', ->
        this.timeout 60000

        DO_TESTS and before (done) ->
            compound = getCompound()
            expect(compound).to.exist
            if compound.memoryDiveReady
                return init done
            compound.on 'memoryDiveReady', ->
                return init done

        providerData = null

        init = (done) ->
            collector = compound.collectors.foursquare
            providerData =
                providerId:  compound.common.constants.providerId.FOURSQUARE
                providerData:
                    token:  testToken
            expect(collector).to.exist
            done()

        describe 'has collectCheckIns that', ->
            it 'throw if no callback is given', DO_TESTS and ->
                expect(collector.collectCheckIns).to.throw 'no arguments'

            it 'collects check-ins for correct provider data', DO_TESTS and (done) ->

                nocks = compound.startNocking 'workers__data__foursquareCollector.1.json'

                counter = 0
                collector.collectCheckIns providerData, (err, item, next) ->
                    return done err if err
                    if item
                        ++counter
                        return next()

                    expectAll()

                expectAll = () ->
                    compound.stopNocking nocks
                    expect(counter).to.be.at.least(testMinExpectedCheckIns)
                    done()
