
expect = (require 'chai').expect
_ = require('lodash')

compound = null
worker = null
User = null
FacebookObject = null
testedUser = null
providerData = null
debug = (require 'debug') 'memdive::workers::facebook::tests'

# Read environment variables required by the test
parseEnvInt = (env) -> env and parseInt(env)
testToken = process.env.MEMORY_DIVE_TEST_FACEBOOK_TOKEN
testUserId = process.env.MEMORY_DIVE_TEST_FACEBOOK_USER_ID
testUserName = process.env.MEMORY_DIVE_TEST_FACEBOOK_USER_NAME
testMinExpectedTaggedPhotos = parseEnvInt(process.env.MEMORY_DIVE_TEST_FACEBOOK_MIN_EXPECTED_TAGGED_PHOTOS)
testMinExpectedUploadedPhotos = parseEnvInt(process.env.MEMORY_DIVE_TEST_FACEBOOK_MIN_EXPECTED_UPLOADED_PHOTOS)
testMinExpectedUploadedVideos = parseEnvInt(process.env.MEMORY_DIVE_TEST_FACEBOOK_MIN_EXPECTED_UPLOADED_VIDEOS)
testMinExpectedTaggedVideos = parseEnvInt(process.env.MEMORY_DIVE_TEST_FACEBOOK_MIN_EXPECTED_TAGGED_VIDEOS)
testMinExpectedLikes = parseEnvInt(process.env.MEMORY_DIVE_TEST_FACEBOOK_MIN_EXPECTED_LIKES)
testMinExpectedPosts = parseEnvInt(process.env.MEMORY_DIVE_TEST_FACEBOOK_MIN_EXPECTED_POSTS)
testMinExpectedNotes = parseEnvInt(process.env.MEMORY_DIVE_TEST_FACEBOOK_MIN_EXPECTED_NOTES)
testMinExpectedAllObjects = parseEnvInt(process.env.MEMORY_DIVE_TEST_FACEBOOK_MIN_EXPECTED_ALL_OBJECTS)

# Skip tests in the test suite unless all environment variables are present
DO_TESTS = testToken and testUserId and testUserName and testMinExpectedTaggedPhotos and testMinExpectedUploadedPhotos and testMinExpectedUploadedVideos and testMinExpectedTaggedVideos and testMinExpectedLikes and testMinExpectedPosts and testMinExpectedNotes and testMinExpectedAllObjects

describe 'facebookWorker module', ->
    this.timeout 6000000

    init = (done) ->
        User = compound.models.User
        expect(User).to.exist
        FacebookObject = compound.models.FacebookObject
        expect(FacebookObject).to.exist
        worker = compound.workers.facebook
        expect(worker).to.exist

        nocks = compound.startNocking 'workers__data__facebookWorker.before.json'

        # We clean the entire db and then create a test user doc and *object*.
        # We use this object in tests that assume correct creation of user docs
        # as then we don't have to screw with timestamp|createdOn interception.
        compound.couch.cleanDb (err) ->
            return done err if err

            userData =
                facebookId: testUserId
                token:  testToken
                profile:
                    username: testUserName
                utcOffset:  1 * 60 * 60 * 1000  #   UTC+1

            User.findOrCreate userData, (err, dbUser) ->
                compound.stopNocking nocks
                expect(err).to.not.exist
                expect(dbUser).to.exist
                expect(dbUser.timestamp).to.equal 0
                expect(dbUser.createdOn).to.equal 0
                testedUser = dbUser
                providerData =
                    userId: dbUser.id
                    providerId: compound.common.constants.providerId.FACEBOOK
                    providerUserId: userData.facebookId
                    providerData:
                        token:  testToken

                compound.consistencyTimeout ->
                    done()


    DO_TESTS and before (done) ->
        # Sometimes cleanup might take longer due to the number of docs
        compound = getCompound()
        expect(compound).to.exist
        if compound.memoryDiveReady
            return init done
        compound.on 'memoryDiveReady', ->
            return init done

    DO_TESTS and beforeEach (done) ->

        nocks = compound.startNocking 'workers__data__facebookWorker.beforeEach.json'

        compound.consistencyTimeout ->
            compound.cleanDbExceptDesignAndUser (err) ->
                return done err if err
                compound.stopNocking nocks
                compound.consistencyTimeout ->
                    done()

    it 'updateUserInfo puts all user related FB objects into db', DO_TESTS and (done) ->

        nocks = compound.startNocking 'workers__data__facebookWorker.1.json'

        FacebookObject.count (err, count) ->
            return done err if err
            expect(count).to.exist
            expect(count).to.equal 0

            worker.updateInfo undefined, providerData, (err) ->
                return done err if err

                compound.consistencyTimeout ->
                    FacebookObject.all { batchSize: 10000 }, (err, items) ->
                        return done err if err
                        compound.stopNocking nocks
                        expect(items).to.exist
                        # We find more but some are duplicates (e.g. a photo doc appearing in both uploaded and tagged)
                        expect(items).to.have.length.of.at.least(testMinExpectedAllObjects)
                        done()

    it 'updateUserUploadedPhotos puts all photos into db', DO_TESTS and (done) ->

        nocks = compound.startNocking 'workers__data__facebookWorker.2.json'

        FacebookObject.all (err, items) ->
            return done err if err
            expect(items).to.exist
            expect(items).to.be.empty

            worker.updateUploadedPhotos providerData, (err) ->
                return done err if err

                compound.consistencyTimeout ->
                    FacebookObject.all (err, items) ->
                        return done err if err
                        compound.stopNocking nocks
                        expect(items).to.exist
                        expect(items).to.have.length.of.at.least(testMinExpectedUploadedPhotos)
                        expect(_.all items, (item) ->
                            return item.type == 'photo' and item.utcOffset == testedUser.utcOffset
                        ).to.be.true
                        done()

    it 'updateUserTaggedPhotos puts all photos into db', DO_TESTS and (done) ->

        nocks = compound.startNocking 'workers__data__facebookWorker.3.json'

        FacebookObject.all (err, items) ->
            return done err if err
            expect(items).to.exist
            expect(items).to.be.empty

            worker.updateTaggedPhotos providerData, (err) ->
                return done err if err

                compound.consistencyTimeout ->
                    FacebookObject.all (err, items) ->
                        return done err if err
                        compound.stopNocking nocks
                        expect(items).to.exist
                        expect(items).to.have.length.of.at.least(testMinExpectedTaggedPhotos)
                        expect(_.all items, (item) ->
                            item.type == 'photo' and item.utcOffset == testedUser.utcOffset
                        ).to.be.true
                        done()

    # I avoided testing this for all the methods as they should all behave the same.
    # I chose the quickest one to save the testing time (as it's already several minutes long)
    it 'updateUserUploadedVideos puts and updates all videos into db', DO_TESTS and (done) ->

        nocks = compound.startNocking 'workers__data__facebookWorker.4.json'

        FacebookObject.all (err, items) ->
            return done err if err
            expect(items).to.exist
            expect(items).to.be.empty

            worker.updateUploadedVideos providerData, (err) ->
                return done err if err

                compound.consistencyTimeout ->
                    FacebookObject.all (err, items) ->
                        return done err if err
                        expect(items).to.exist
                        expect(items).to.have.length.of.at.least(testMinExpectedUploadedVideos)
                        expect(_.all items, (item) ->
                            item.type == 'video' and item.utcOffset == testedUser.utcOffset
                        ).to.equal true, 'not all items are videos with correct UTC offset'
                        # Get revision for each doc id.
                        revisions = {}
                        _.each items, (item) ->
                            revisions[item._id] = item._rev

                        compound.consistencyTimeout ->
                            # Now update all the items again and check that the revisions changed.
                            worker.updateUploadedVideos providerData, (err) ->
                                return done err if err

                                FacebookObject.all (err, items) ->
                                    return done err if err
                                    compound.stopNocking nocks
                                    expect(items).to.exist
                                    expect(items).to.have.length.of.at.least(testMinExpectedUploadedVideos)
                                    expect(_.all items, (item) ->
                                        # All items now have different revisions.
                                        revisions[item._id] != item._rev
                                    ).to.equal true, 'not all items have been updated'
                                    done()


    it 'updateUserTaggedVideos puts all videos into db', DO_TESTS and (done) ->

        nocks = compound.startNocking 'workers__data__facebookWorker.5.json'

        FacebookObject.all (err, items) ->
            return done err if err
            expect(items).to.exist
            expect(items).to.be.empty

            worker.updateTaggedVideos providerData, (err) ->
                return done err if err

                compound.consistencyTimeout ->
                    FacebookObject.all (err, items) ->
                        return done err if err
                        compound.stopNocking nocks
                        expect(items).to.exist
                        expect(items).to.have.length.of.at.least(testMinExpectedTaggedVideos)
                        expect(_.all items, (item) ->
                            item.type == 'video' and item.utcOffset == testedUser.utcOffset
                        ).to.be.true
                        done()

    it 'updateUserLikes puts all likes into db', DO_TESTS and (done) ->

        nocks = compound.startNocking 'workers__data__facebookWorker.6.json'

        FacebookObject.all (err, items) ->
            return done err if err
            expect(items).to.exist
            expect(items).to.be.empty

            worker.updateLikes providerData, (err) ->
                return done err if err

                compound.consistencyTimeout ->
                    FacebookObject.all (err, items) ->
                        return done err if err
                        compound.stopNocking nocks
                        expect(items).to.exist
                        expect(items).to.have.length.of.at.least(testMinExpectedLikes)
                        expect(_.all items, (item) ->
                            item.type == 'like' and item.utcOffset == testedUser.utcOffset
                        ).to.be.true
                        done()

    it 'updateUserPosts puts all posts into db', DO_TESTS and (done) ->

        nocks = compound.startNocking 'workers__data__facebookWorker.7.json'

        FacebookObject.all (err, items) ->
            return done err if err
            expect(items).to.exist
            expect(items).to.be.empty

            worker.updatePosts providerData, (err) ->
                return done err if err

                compound.consistencyTimeout ->
                    FacebookObject.all (err, items) ->
                        return done err if err
                        compound.stopNocking nocks
                        expect(items).to.exist
                        expect(items).to.have.length.of.at.least(testMinExpectedPosts)
                        expect(_.all items, (item) ->
                            item.type == 'post' and item.utcOffset == testedUser.utcOffset
                        ).to.be.true
                        done()

    it 'updateUserNotes puts all notes into db', DO_TESTS and (done) ->

        nocks = compound.startNocking 'workers__data__facebookWorker.8.json'

        FacebookObject.all (err, items) ->
            return done err if err
            expect(items).to.exist
            expect(items).to.be.empty

            worker.updateNotes providerData, (err) ->
                return done err if err

                compound.consistencyTimeout ->
                    FacebookObject.all (err, items) ->
                        return done err if err
                        compound.stopNocking nocks
                        expect(items).to.exist
                        expect(items).to.have.length.of.at.least(testMinExpectedNotes)
                        expect(_.all items, (item) ->
                            item.type == 'note' and item.utcOffset == testedUser.utcOffset
                        ).to.be.true
                        done()

    # Test bulk insertion through couchdb driver. There was some suspicion that this wasn't working
    # correctly so I added this temp test. It turned out to be just a coincidence but now I'm sorry
    # to delete a perfectly fine test (2014-02-15)
    it 'impromptu testing of couchdb bulk', DO_TESTS and (done) ->

        nocks = compound.startNocking 'workers__data__facebookWorker.9.json'

        FacebookObject.all (err, items) ->
            return done err if err
            expect(items).to.exist
            expect(items).to.be.empty

            # It looked like bulk loading was artificially limited to 1,000 docs so we tested to see
            # that 2,000 docs could be correctly inserted.
            docs = (FacebookObject.createPhotoDoc(providerData, {
                id:             num
                name:           'fake-' + num
                created_time:   (new Date(12345)).toISOString()
                utcOffset:      testedUser.utcOffset
            }) for num in [1..2000])
            compound.couch.bulk { docs: docs }, (err) ->
                return done err if err

                compound.consistencyTimeout ->
                    FacebookObject.all (err, items) ->
                        return done err if err
                        compound.stopNocking nocks
                        expect(items).to.exist
                        expect(items.length).to.equal 2000 # Fixing results
                        expect(_.all items, (item) ->
                            item.type == 'photo' and item.utcOffset == testedUser.utcOffset
                        ).to.be.true
                        done()
