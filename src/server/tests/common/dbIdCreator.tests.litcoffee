
    chai = require 'chai'
    expect = chai.expect

    compound = null
    dbIdCreator = null
    constants = null
    error = null

    describe 'dbIdCreator module', ->
        this.timeout 15000
        before (done) ->
            compound = getCompound()
            expect(compound).to.exist
            if compound.memoryDiveReady
                return init done
            compound.on 'memoryDiveReady', ->
                return init done

        init = (done) ->
            dbIdCreator = compound.common.dbIdCreator
            expect(dbIdCreator).to.exist
            error = compound.common.constants.error
            expect(error).to.exist
            done()

        describe 'has create function that', ->
            it 'returns generic statistically unique ID based on hash of all its arguments', ->
                id = dbIdCreator.create()
                expect(id).to.equal 'undefined-f96cea198ad1dd5617ac084a3d92c6107708c0ef'

                id = dbIdCreator.create 'test'
                expect(id).to.equal 'test-8d145d90a86e6e0dc36351d71aa5f3e070c73ad3'

                id = dbIdCreator.create 'test', undefined
                expect(id).to.equal 'test-8d145d90a86e6e0dc36351d71aa5f3e070c73ad3'

                id = dbIdCreator.create 'test', 123
                expect(id).to.equal 'test-fd97bf6d3c81d359de76de983d529e72fa8b53f6'

                id = dbIdCreator.create 'test', 123, { test: 456 }
                expect(id).to.equal 'test-5d0e3eeebf896a5c9d31a645c19bbbbfada9ceb8'

        describe 'has specialized functions that', ->
            it 'return unique IDs for UserData docs', ->
                providerData =
                    userId: '123'
                    providerId: 'test'
                    providerUserId: '456'
                id = dbIdCreator.createUserDataObjectId providerData, '789'
                expect(id).to.equal 'test-b06dab1d7c00c534fd9f816a13cf957992a7eae6'

            it 'return unique IDs for UserDataProvider docs', ->
                providerData =
                    userId: '123'
                    providerId: 'test'
                    providerUserId: '456'
                id = dbIdCreator.createUserDataProviderObjectId providerData
                expect(id).to.equal 'test-be0138f6d1dce3ba2b079c85d9d1d62fcb09a2c5'

            it 'return unique IDs for UserBackupProvider docs', ->
                providerData =
                    userId: '123'
                    providerId: 'test'
                    providerUserId: '456'
                id = dbIdCreator.createUserBackupProviderObjectId providerData
                expect(id).to.equal 'test-3b726ea9ece11c01acf3b6a79746d2a06c4acaeb'
