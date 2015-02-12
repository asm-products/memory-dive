    expect = (require 'chai').expect
    _ = require 'lodash'

    compound = null
    worker = null
    User = null
    DropboxObject = null
    testUser = null

    # Read environment variables required by the test
    parseEnvInt = (env) -> env and parseInt(env)
    testToken = process.env.MEMORY_DIVE_TEST_FACEBOOK_TOKEN
    testUserId = process.env.MEMORY_DIVE_TEST_FACEBOOK_USER_ID
    testUserName = process.env.MEMORY_DIVE_TEST_FACEBOOK_USER_NAME
    testDropboxToken = process.env.MEMORY_DIVE_TEST_DROPBOX_TOKEN
    testMinExpectedUserPhotosAndVideos = parseEnvInt(process.env.MEMORY_DIVE_TEST_DROPBOX_MIN_EXPECTED_USER_PHOTOS_AND_VIDEOS)
    testMinExpectedMimeTypes = parseEnvInt(process.env.MEMORY_DIVE_TEST_DROPBOX_MIN_EXPECTED_MIME_TYPES)

    # Skip tests in the test suite unless all environment variables are present
    DO_TESTS = testToken and testUserId and testUserName and testDropboxToken and testMinExpectedUserPhotosAndVideos and testMinExpectedMimeTypes

    describe 'dropboxWorker module', ->
        this.timeout 600000

        init = (done) ->
            User = compound.models.User
            expect(User).to.exist
            DropboxObject = compound.models.DropboxObject
            expect(DropboxObject).to.exist
            worker = compound.workers.dropbox
            expect(worker).to.exist

            userData =
                facebookId: testUserId
                token:  testToken
                profile:
                    username: testUserName
                utcOffset: 1 * 60 * 60 * 1000   #   UTC+1

Because we are using timestamps for createdOn and timestamp fields we have to replaces their values in the body with the value specified in the nock JSON.

            nocks = compound.startNocking 'workers__data__dropboxWorker.before.json'

            # We clean the entire db and then create a test user doc and *object*.
            # We use this object in tests that assume correct creation of user docs
            # as then we don't have to screw with timestamp|createdOn interception.
            compound.couch.cleanDb (err) ->
                return done err if err

                User.findOrCreate userData, (err, dbUser) ->
                    expect(err).to.not.exist
                    expect(dbUser).to.exist
                    testUser = dbUser
                    compound.stopNocking nocks
                    done()

        DO_TESTS and before (done) ->
            compound = getCompound()
            expect(compound).to.exist
            if compound.memoryDiveReady
                return init done
            compound.on 'memoryDiveReady', ->
                return init done

        DO_TESTS and beforeEach (done) ->
            nocks = compound.startNocking 'workers__data__dropboxWorker.beforeEach.json'
            compound.consistencyTimeout ->
                compound.cleanDbExceptDesignAndUser (err) ->
                    return done err if err
                    compound.stopNocking nocks
                    done()

        it 'updateUserPhotosAndVideos puts all photos and videos into db', DO_TESTS and (done) ->

We use scope filtering to intercept api*.dropbox.com calls made by Dropbox module.

            nocks = compound.startNocking 'workers__data__dropboxWorker.1.json', {
                preprocessor: (nockDefs) ->
                    _.each nockDefs, (nockDef) ->
                        if nockDef.scope.indexOf('dropbox.com') != -1
                            nockDef.options = nockDef.options || {};
                            nockDef.options.filteringScope = (scope) ->
                                test = /^https:\/\/api[0-9]*.dropbox.com/.test(scope)
                                return test
            }

We manually filter the nocks that we know will change depending on the time and current content.

            compound.consistencyTimeout ->
                DropboxObject.all (err, items) ->
                    return done err if err
                    expect(items).to.exist
                    expect(items).to.be.empty

                    providerData =
                        _id:     'testProviderId'
                        userId: testUser.id
                        providerId: compound.common.constants.providerId.DROPBOX
                        providerUserId: 12345
                        providerData:
                            token:  testDropboxToken

                    worker.updateUserPhotosAndVideos undefined, providerData, (err) ->
                        return done err if err

                        compound.consistencyTimeout ->
                            DropboxObject.all (err, items) ->
                                compound.stopNocking nocks
                                return done err if err

                                expect(items).to.exist
                                expect(items).to.have.length.of.at.least(testMinExpectedUserPhotosAndVideos)
                                uniqueMimeTypes = (mimeTypes, item) ->
                                    mimeType = item.mimeType
                                    index = _.findIndex mimeTypes, (mimeType) ->
                                        mimeType == item.mimeType
                                    if index is -1
                                        mimeTypes.push mimeType
                                    return mimeTypes
                                mimeTypes = _.reduce items, uniqueMimeTypes, []
                                expect(mimeTypes).to.have.length.of.at.least(testMinExpectedMimeTypes)
                                done()
