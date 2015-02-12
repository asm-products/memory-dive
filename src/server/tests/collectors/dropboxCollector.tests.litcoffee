
    expect = (require 'chai').expect
    _ = require 'lodash'

    compound = null
    collector = null

    # Read environment variables required by the test
    parseEnvInt = (env) -> env and parseInt(env)
    testToken = process.env.MEMORY_DIVE_TEST_DROPBOX_TOKEN
    testMinExpectedUserPhotosAndVideos = parseEnvInt(process.env.MEMORY_DIVE_TEST_DROPBOX_MIN_EXPECTED_USER_PHOTOS_AND_VIDEOS)

    # Skip tests in the test suite unless all environment variables are present
    DO_TESTS = testToken and testMinExpectedUserPhotosAndVideos

    describe 'dropboxCollector module', ->

        this.timeout 600000

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
            collector = compound.collectors.dropbox
            expect(collector).to.exist
            done()

        describe 'has collectUserPhotosAndVideos that', ->
            it 'throw if no callback is given', DO_TESTS and ->
                expect(collector.collectUserPhotosAndVideos).to.throw 'no arguments'

            it 'collects photos and videos for correct provider data', DO_TESTS and (done) ->

We use scope filtering to intercept api*.dropbox.com calls made by Dropbox module.

                nocks = compound.startNocking 'workers__data__dropboxCollector.1.json', {
                    preprocessor: (nockDefs) ->
                        _.each nockDefs, (nockDef) ->
                            if nockDef.scope.indexOf('dropbox.com') != -1
                                nockDef.options = nockDef.options || {};
                                nockDef.options.filteringScope = (scope) ->
                                    /^https:\/\/api[0-9]*.dropbox.com/.test(scope)
                }

                counter = 0
                collector.collectUserPhotosAndVideos providerData, (err, item, next) ->
                    return done err if err
                    if item
                        ++counter
                        return next()

                    expectAll()

                expectAll = () ->
                    expect(counter).to.be.at.least(testMinExpectedUserPhotosAndVideos)
                    compound.stopNocking nocks
                    done()
