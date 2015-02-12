
    expect = (require 'chai').expect
    _ = require('lodash')

    compound = null
    creator = null
    providerId = null

    describe 'api1UrlCreator module', ->
        this.timeout(10000)

        init = (done) ->
            creator = compound.common.api1UrlCreator
            expect(creator).to.exist
            providerId = compound.common.constants.providerId
            expect(providerId).to.exist
            done()

        before (done) ->
            compound = getCompound()
            expect(compound).to.exist
            if compound.memoryDiveReady
                return init done
            compound.on 'memoryDiveReady', ->
                return init done

        it 'getDataProviderAuthAddPath that returns correct URLs for all providers', () ->
            expect(creator.getDataProviderAuthAddPath(providerId.TWITTER)).to.equal '/1/web/user/auth/data/twitter/add'
            expect(creator.getDataProviderAuthAddPath(providerId.FACEBOOK)).to.equal '/1/web/user/auth/data/facebook/add'
            expect(creator.getDataProviderAuthAddPath(providerId.DROPBOX)).to.equal '/1/web/user/auth/data/dropbox/add'
            expect(creator.getDataProviderAuthAddPath(providerId.EVERNOTE)).to.equal '/1/web/user/auth/data/evernote/add'
            expect(creator.getDataProviderAuthAddPath(providerId.GOOGLE_PLUS)).to.equal '/1/web/user/auth/data/google-plus/add'
            # TEXT_IMPORT doesn't have add path
            expect(creator.getDataProviderAuthAddPath(providerId.SLACK)).to.equal '/1/web/user/auth/data/slack/add'
            expect(creator.getDataProviderAuthAddPath(providerId.FOURSQUARE)).to.equal '/1/web/user/auth/data/foursquare/add'
            expect(_.keys(providerId).length).to.equal 8, "don't forget to add tests for new data providers"

        it 'getDataProviderAuthCallbackPath that returns correct URLs for all providers', () ->
            expect(creator.getDataProviderAuthCallbackPath(providerId.TWITTER)).to.equal '/1/web/user/auth/data/twitter/callback'
            expect(creator.getDataProviderAuthCallbackPath(providerId.FACEBOOK)).to.equal '/1/web/user/auth/data/facebook/callback'
            expect(creator.getDataProviderAuthCallbackPath(providerId.DROPBOX)).to.equal '/1/web/user/auth/data/dropbox/callback'
            expect(creator.getDataProviderAuthCallbackPath(providerId.EVERNOTE)).to.equal '/1/web/user/auth/data/evernote/callback'
            expect(creator.getDataProviderAuthCallbackPath(providerId.GOOGLE_PLUS)).to.equal '/1/web/user/auth/data/google-plus/callback'
            # TEXT_IMPORT doesn't have callback path
            expect(creator.getDataProviderAuthCallbackPath(providerId.SLACK)).to.equal '/1/web/user/auth/data/slack/callback'
            expect(creator.getDataProviderAuthCallbackPath(providerId.FOURSQUARE)).to.equal '/1/web/user/auth/data/foursquare/callback'
            expect(_.keys(providerId).length).to.equal 8, "don't forget to add tests for new data providers"

        it 'getBackupProviderAuthAddPath that returns correct URLs for all providers', () ->
            expect(creator.getBackupProviderAuthAddPath(providerId.DROPBOX)).to.equal '/1/web/user/auth/backup/dropbox/add'

        it 'getBackupProviderAuthCallbackPath that returns correct URLs for all providers', () ->
            expect(creator.getBackupProviderAuthCallbackPath(providerId.DROPBOX)).to.equal '/1/web/user/auth/backup/dropbox/callback'
