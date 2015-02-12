
    chai = require 'chai'
    expect = chai.expect

    compound = null
    DropboxObject = null

    describe 'DropboxObject model', ->
        this.timeout 15000

        before (done) ->
            compound = getCompound()
            expect(compound).to.exist
            if compound.memoryDiveReady
                return init done
            compound.on 'memoryDiveReady', ->
                return init done

        init = (done) ->
            DropboxObject = compound.models.DropboxObject
            expect(DropboxObject).to.exist
            done()

        providerData =
            userId: 'xyz'
            providerId: 'dbox'
            providerUserId: 12345

        dropboxData =
            mimeType:       'mime'
            path:           'path'
            extra:
                test: 'test property'
            utcOffset:      -10000
            clientModifiedAt:   new Date()
            modifiedAt:         new Date()

        it 'correctly creates instances', ->
            object = DropboxObject.createObject providerData, dropboxData
            expect(object).to.exist
            expect(object.id).to.equal 'dbox-e141f7aac645c724ba6d35d914465f72967a569f'
            expect(object.mimeType).to.equal dropboxData.mimeType
            expect(object.path).to.equal dropboxData.path
            expect(object.extra).to.equal dropboxData.extra
            expect(object.utcOffset).to.equal dropboxData.utcOffset
            expect(object.createdTime).to.equal dropboxData.clientModifiedAt.getTime()
            expect(object.updatedTime).to.equal dropboxData.modifiedAt.getTime()
