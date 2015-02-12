
We test the functions of the CouchDb design document as part of the logic is offloaded to them (especially construction of JSON objects out of documents from different services). This logic offloading allows better scalability as Node is single-threaded whereas CouchDb is built for massive parallel processing. If this ever changes and better scalability can be obtained on the Node then we simply move the transformation code to its end.

    expect = (require 'chai').expect
    _ = require 'lodash'
    objectHistoricMetadata = require '../../db/design/objectHistoricMetadata'
    objectMetadata = require '../../db/design/objectMetadata'
    userData = require '../../db/design/userData'
    userDataPerYear = require '../../db/design/userDataPerYear'
    userDataUtcOffset = require '../../db/design/userDataUtcOffset'
    userText = require '../../db/design/userText'

    compound = null
    collector = null

    describe 'CouchDb design modules', ->
        this.timeout 60000

        before (done) ->
            compound = getCompound()
            expect(compound).to.exist
            if compound.memoryDiveReady
                return init done
            compound.on 'memoryDiveReady', ->
                return init done

Test docs for different test object.

        fbCreatedTime = new Date('2014-03-06 22:15')
        fbUpdatedTime = fbCreatedTime.getTime() + 1000
        fbTestDoc =
            model:          'FacebookObject'
            userId:         '12345'
            modelId:        '56789'
            name:           'test name'
            type:           'photo'
            extra:
                test:       'test'
            createdTime:    fbCreatedTime.getTime()
            updatedTime:    fbUpdatedTime

        twCreatedTime = new Date('2014-03-07 07:48')
        twUpdatedTime = twCreatedTime.getTime() + 1000
        twTestDoc =
            model:          'TwitterObject'
            userId:         '12345'
            type:           'photo'
            extra:
                test:       'test'
            createdTime:    twCreatedTime.getTime()
            updatedTime:    twUpdatedTime

        dboxCreatedTime = new Date('2014-03-07 08:02')
        dboxUpdatedTime = dboxCreatedTime.getTime() + 1000
        dboxTestDoc =
            model:          'DropboxObject'
            userId:         '12345'
            mimeType:       'image/jpeg'
            extra:
                test:       'test'
            createdTime:    dboxCreatedTime.getTime()
            updatedTime:    dboxUpdatedTime

        enCreatedTime = new Date('2014-03-07 08:02')
        enUpdatedTime = enCreatedTime.getTime() + 1000
        enTestDoc =
            model:          'EvernoteObject'
            userId:         '12345'
            modelId:        '67890'
            extra:
                test:       'test'
            createdTime:    enCreatedTime.getTime()
            updatedTime:    enUpdatedTime

        slCreatedTime = new Date('2014-05-23 02:23')
        slUpdatedTime = slCreatedTime.getTime() + 1000
        slTestDoc =
            model:          'SlackObject'
            userId:         'xyz123'
            modelId:        'opq567'
            extra:
                subtype:    'test'
            createdTime:    slCreatedTime.getTime()
            updatedTime:    slUpdatedTime

        testDocs = [fbTestDoc, twTestDoc, dboxTestDoc, enTestDoc, slTestDoc];

Once everything has been initialized replace/create global emit, getRow and provides CouchDb functions so that we can test the internals of map and list functions.

        emitTester = () ->
        getRowTester = () ->
        providesTester = () ->
        indexTester = () ->

        init = (done) ->
            `emit = function(key, value) {
                emitTester(key, value);
            }`
            `getRow = function() {
                return getRowTester();
            }`
            `provides = function(format, outputGeneratorFunction) {
                //  We ignore format parameter as that's used only by CouchDb.
                return outputGeneratorFunction();
            }`
            `index = function(name, value) {
                indexTester(name, value);
            }`
            done()

        it 'has views, lists, shows, searches', ->
            expect(objectHistoricMetadata).to.exist
            expect(objectMetadata).to.exist
            expect(userData).to.exist
            expect(userDataPerYear).to.exist
            expect(userDataUtcOffset).to.exist
            expect(userText).to.exist

        describe 'has userData map function', ->
            it 'that doesn\'t emit keys for unknown doc types', ->
                testDoc =
                    model: 'SomeOtherKindOfObject'

                emitCounter = 0
                emitTester = (key, value) ->
                    ++emitCounter

                userData.views.view.map testDoc
                expect(emitCounter).to.equal 0

            it 'that emits keys FacebookObject docs', ->
                emitCounter = 0
                emitTester = (key, value) ->
                    ++emitCounter
                    expect(key).to.be.ok
                    expect(key).to.not.be.empty
                    expect(key).to.be.array
                    expect(key.length).to.equal 5
                    expect(key[0]).to.equal fbTestDoc.userId
                    expect(key[1]).to.equal fbCreatedTime.getUTCMonth()
                    expect(key[2]).to.equal fbCreatedTime.getUTCDate()
                    expect(key[3]).to.equal fbTestDoc.model
                    expect(key[4]).to.equal fbCreatedTime.getTime()
                    expect(value).to.be.undefined

                userData.views.view.map fbTestDoc
                expect(emitCounter).to.equal 1

            it 'that emits keys TwitterObject docs', ->
                emitCounter = 0
                emitTester = (key, value) ->
                    ++emitCounter
                    expect(key).to.be.ok
                    expect(key).to.be.array
                    expect(key.length).to.equal 5
                    expect(key[0]).to.equal twTestDoc.userId
                    expect(key[1]).to.equal twCreatedTime.getUTCMonth()
                    expect(key[2]).to.equal twCreatedTime.getUTCDate()
                    expect(key[3]).to.equal twTestDoc.model
                    expect(key[4]).to.equal twCreatedTime.getTime()
                    expect(value).to.be.undefined

                userData.views.view.map twTestDoc
                expect(emitCounter).to.equal 1

            it 'that emits keys DropboxObject docs', ->
                emitCounter = 0
                emitTester = (key, value) ->
                    ++emitCounter
                    expect(key).to.be.ok
                    expect(key).to.be.array
                    expect(key.length).to.equal 5
                    expect(key[0]).to.equal dboxTestDoc.userId
                    expect(key[1]).to.equal dboxCreatedTime.getUTCMonth()
                    expect(key[2]).to.equal dboxCreatedTime.getUTCDate()
                    expect(key[3]).to.equal dboxTestDoc.model
                    expect(key[4]).to.equal dboxCreatedTime.getTime()
                    expect(value).to.be.undefined

                userData.views.view.map dboxTestDoc
                expect(emitCounter).to.equal 1

            it 'that emits keys EvernoteObject docs', ->
                emitCounter = 0
                emitTester = (key, value) ->
                    ++emitCounter
                    expect(key).to.be.ok
                    expect(key).to.be.array
                    expect(key.length).to.equal 5
                    expect(key[0]).to.equal enTestDoc.userId
                    expect(key[1]).to.equal enCreatedTime.getUTCMonth()
                    expect(key[2]).to.equal enCreatedTime.getUTCDate()
                    expect(key[3]).to.equal enTestDoc.model
                    expect(key[4]).to.equal enCreatedTime.getTime()
                    expect(value).to.be.undefined

                userData.views.view.map enTestDoc
                expect(emitCounter).to.equal 1

            it 'that emits keys SlackObject docs', ->
                emitCounter = 0
                emitTester = (key, value) ->
                    ++emitCounter
                    expect(key).to.be.ok
                    expect(key).to.be.array
                    expect(key.length).to.equal 5
                    expect(key[0]).to.equal slTestDoc.userId
                    expect(key[1]).to.equal slCreatedTime.getUTCMonth()
                    expect(key[2]).to.equal slCreatedTime.getUTCDate()
                    expect(key[3]).to.equal slTestDoc.model
                    expect(key[4]).to.equal slCreatedTime.getTime()
                    expect(value).to.be.undefined

                userData.views.view.map slTestDoc
                expect(emitCounter).to.equal 1

            it 'that indexes docs even with no createdTime', ->
                fbUpdatedTimeDate = new Date(fbUpdatedTime)

                emitCounter = 0
                emitTester = (key, value) ->
                    ++emitCounter
                    expect(key).to.be.ok
                    expect(key).to.be.array
                    expect(key.length).to.equal 5
                    expect(key[0]).to.equal fbTestDoc.userId
                    expect(key[1]).to.equal fbUpdatedTimeDate.getUTCMonth()
                    expect(key[2]).to.equal fbUpdatedTimeDate.getUTCDate()
                    expect(key[3]).to.equal fbTestDoc.model
                    expect(key[4]).to.equal fbUpdatedTimeDate.getTime()
                    expect(value).to.be.undefined

                clonedFbTestDoc = _.clone fbTestDoc
                clonedFbTestDoc.createdTime = null

                userData.views.view.map clonedFbTestDoc
                expect(emitCounter).to.equal 1

        describe 'has userData reduce function', ->
            it 'that is a build-in count function', ->
                expect(userData.views.view.reduce).to.equal '_count'

        describe 'has userText index', ->
            it 'has correct properties', ->
                expect(userText.indexes.index.analyzer).to.equal 'standard'
                expect(Object.keys(userText.indexes.index).length).to.equal 2

            it 'that indexes FacebookObjects', ->
                indexCounter = 0
                indexTester = (name, value) ->
                    ++indexCounter
                    if indexCounter == 1
                        expect(name).to.equal 'userId'
                        expect(value).to.equal fbTestDoc.userId
                    else
                        expect(name).to.equal 'text'
                        expect(value).to.equal fbTestDoc.name

                userText.indexes.index.index fbTestDoc
                expect(indexCounter).to.equal 2
