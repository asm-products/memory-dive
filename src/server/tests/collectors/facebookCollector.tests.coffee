expect = (require 'chai').expect
nock   = require 'nock'
path   = require 'path'
_ = require 'lodash'

compound = null
collector = null

# Read environment variables required by the test
parseEnvInt = (env) -> env and parseInt(env)
testToken = process.env.MEMORY_DIVE_TEST_FACEBOOK_TOKEN
testUserId = process.env.MEMORY_DIVE_TEST_FACEBOOK_USER_ID
testMinExpectedTaggedPhotos = parseEnvInt(process.env.MEMORY_DIVE_TEST_FACEBOOK_MIN_EXPECTED_TAGGED_PHOTOS)
testMinExpectedUploadedPhotos = parseEnvInt(process.env.MEMORY_DIVE_TEST_FACEBOOK_MIN_EXPECTED_UPLOADED_PHOTOS)
testMinExpectedUploadedVideos = parseEnvInt(process.env.MEMORY_DIVE_TEST_FACEBOOK_MIN_EXPECTED_UPLOADED_VIDEOS)
testMinExpectedTaggedVideos = parseEnvInt(process.env.MEMORY_DIVE_TEST_FACEBOOK_MIN_EXPECTED_TAGGED_VIDEOS)
testMinExpectedLikes = parseEnvInt(process.env.MEMORY_DIVE_TEST_FACEBOOK_MIN_EXPECTED_LIKES)
testMinExpectedPosts = parseEnvInt(process.env.MEMORY_DIVE_TEST_FACEBOOK_MIN_EXPECTED_POSTS)
testMinExpectedNotes = parseEnvInt(process.env.MEMORY_DIVE_TEST_FACEBOOK_MIN_EXPECTED_NOTES)

# Skip tests in the test suite unless all environment variables are present
DO_TESTS = testToken and testUserId and testMinExpectedTaggedPhotos and testMinExpectedUploadedPhotos and testMinExpectedUploadedVideos and testMinExpectedTaggedVideos and testMinExpectedLikes and testMinExpectedPosts and testMinExpectedNotes

describe 'facebookCollector module', ->
    this.timeout 600000

    DO_TESTS and before (done) ->
        compound = getCompound()
        expect(compound).to.exist
        if compound.memoryDiveReady
            return init done
        compound.on 'memoryDiveReady', ->
            return init done

    providerData =
        providerUserId: testUserId
        providerData:
            token: testToken

    init = (done) ->
        collector = compound.collectors.facebook
        expect(collector).to.exist
        done()

    describe 'collect user data functions', ->
        it 'throw if no callback is given', DO_TESTS and ->
            expect(collector.collectData).to.throw
            expect(collector.collectUploadedPhotos).to.throw
            expect(collector.collectTaggedPhotos).to.throw
            expect(collector.collectUploadedVideos).to.throw
            expect(collector.collectTaggedVideos).to.throw
            expect(collector.collectPosts).to.throw
            expect(collector.collectNotes).to.throw

    describe 'collectUploadedPhotos', ->
        it 'collects all uploaded photos', DO_TESTS and (done) ->
            counter = 0
            nocks = compound.startNocking 'collectors__data__facebookCollector.collectUploadedPhotos.1.json'
            collector.collectUploadedPhotos providerData, (err, item, next) ->
                return done err if err
                if item
                    ++counter
                    return next()

                expectAll()

            expectAll = () ->
                expect(counter).to.be.at.least(testMinExpectedUploadedPhotos)
                compound.stopNocking nocks
                done()

    describe 'collectTaggedPhotos', ->
        it 'collects all tagged photos', DO_TESTS and (done) ->
            counter = 0
            nocks = compound.startNocking 'collectors__data__facebookCollector.collectTaggedPhotos.1.json'
            collector.collectTaggedPhotos providerData, (err, item, next) ->
                return done err if err
                if item
                    ++counter
                    return next()

                expectAll()

            expectAll = () ->
                expect(counter).to.be.at.least(testMinExpectedTaggedPhotos)
                compound.stopNocking nocks
                done()

    describe 'collectUploadedVideos', ->
        it 'collects all uploaded videos', DO_TESTS and (done) ->
            counter = 0
            nocks = compound.startNocking 'collectors__data__facebookCollector.collectUploadedVideos.1.json'
            collector.collectUploadedVideos providerData, (err, item, next) ->
                return done err if err
                if item
                    ++counter
                    return next()

                expectAll()

            expectAll = () ->
                expect(counter).to.be.at.least(testMinExpectedUploadedVideos)
                compound.stopNocking nocks
                done()

    describe 'collectTaggedVideos', ->
        it 'collects all tagged videos', DO_TESTS and (done) ->
            counter = 0
            nocks = compound.startNocking 'collectors__data__facebookCollector.collectTaggedVideos.1.json'
            collector.collectTaggedVideos providerData, (err, item, next) ->
                return done err if err
                if item
                    ++counter
                    return next()

                expectAll()

            expectAll = () ->
                compound.stopNocking nocks
                expect(counter).to.be.at.least(testMinExpectedTaggedVideos)
                done()

    describe 'collectLikes', ->
        it 'collects all likes', DO_TESTS and (done) ->
            counter = 0
            nocks = compound.startNocking 'collectors__data__facebookCollector.collectLikes.1.json'
            collector.collectLikes providerData, (err, item, next) ->
                return done err if err
                if item
                    ++counter
                    return next()

                expectAll()

            expectAll = () ->
                compound.stopNocking nocks
                expect(counter).to.be.at.least(testMinExpectedLikes)
                done()

    describe 'collectPosts', ->
        it 'collects all posts', DO_TESTS and (done) ->
            counter = 0
            nocks = compound.startNocking 'collectors__data__facebookCollector.collectPosts.1.json'
            collector.collectPosts providerData, (err, item, next) ->
                return done err if err
                if item
                    ++counter
                    return next()

                expectAll()

            expectAll = () ->
                compound.stopNocking nocks
                expect(counter).to.be.at.least(testMinExpectedPosts)
                done()

    describe 'collectNotes', ->
        it 'collects all notes', DO_TESTS and (done) ->
            counter = 0
            nocks = compound.startNocking 'collectors__data__facebookCollector.collectNotes.1.json'
            collector.collectNotes providerData, (err, item, next) ->
                return done err if err
                if item
                    ++counter
                    return next()

                expectAll()

            expectAll = () ->
                compound.stopNocking nocks
                expect(counter).to.be.at.least(testMinExpectedNotes)
                done()

    describe 'collectPicture', ->
        it 'collects picture', DO_TESTS and (done) ->
            nocks = compound.startNocking 'collectors__data__facebookCollector.collectPicture.1.json'
            collector.collectPicture providerData, (err, picture) ->
                compound.stopNocking nocks
                expect(picture).to.be.ok
                expect(picture.url).to.be.ok
                done()
