
    expect = (require 'chai').expect
    _ = require('lodash')

    compound = null
    factory = null
    constProviderId = null

    describe 'objectFactory module', ->
        this.timeout(10000)

        init = (done) ->
            factory = compound.common.objectFactory
            expect(factory).to.exist
            constProviderId = compound.common.constants.providerId
            expect(constProviderId).to.exist
            done()

        before (done) ->
            compound = getCompound()
            expect(compound).to.exist
            if compound.memoryDiveReady
                return init done
            compound.on 'memoryDiveReady', ->
                return init done

        describe 'has producePersistor function that', ->
            it 'produces correct persistor for Dropbox', () ->
                dropboxPersistor = factory.producePersistor constProviderId.DROPBOX
                expect(dropboxPersistor).to.exist
                expect(dropboxPersistor).to.be.equal compound.persistors.dropbox

            it 'produces undefined for unknown provider ID', () ->
                dropboxPersistor = factory.producePersistor 'whatever'
                expect(dropboxPersistor).to.be.undefined
