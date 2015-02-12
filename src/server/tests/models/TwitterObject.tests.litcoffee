
    chai = require 'chai'
    expect = chai.expect

    compound = null
    TwitterObject = null

    describe 'TwitterObject model', ->
        this.timeout 15000

        before (done) ->
            compound = getCompound()
            expect(compound).to.exist
            if compound.memoryDiveReady
                return init done
            compound.on 'memoryDiveReady', ->
                return init done

        init = (done) ->
            TwitterObject = compound.models.TwitterObject
            expect(TwitterObject).to.exist
            done()

        providerData =
            userId: 'xyz'
            providerId: 'tw'
            providerUserId: 12345

        it 'correctly creates plain status instances', ->
            twitterData =
                id:         67890
                text:       'test'
                utcOffset:  -10000
                created_at: (new Date()).toISOString()

            object = TwitterObject.createStatusObject providerData, twitterData
            expect(object).to.exist
            expect(object.id).to.equal 'tw-afa11eb02e31deff5838de405b9c197745c01d6a'
            expect(object.text).to.equal twitterData.text
            expect(object.extra).to.exist
            expect(object.extra.retweeted).to.equal false
            expect(object.extra.by).to.be.undefined
            expect(object.utcOffset).to.equal twitterData.utcOffset
            expect(object.createdTime).to.equal new Date(twitterData.created_at).getTime()

        it 'correctly creates retweeted status instances', ->
            twitterData =
                id:         67890
                utcOffset:  -10000
                retweeted_status:
                    text: 'test'
                    user:
                        screen_name: 'whomever'

                created_at: (new Date()).toISOString()

            object = TwitterObject.createStatusObject providerData, twitterData
            expect(object).to.exist
            expect(object.id).to.equal 'tw-afa11eb02e31deff5838de405b9c197745c01d6a'
            expect(object.text).to.equal twitterData.retweeted_status.text
            expect(object.extra).to.exist
            expect(object.extra.retweeted).to.equal true
            expect(object.extra.by).to.be.equal twitterData.retweeted_status.user.screen_name
            expect(object.utcOffset).to.equal twitterData.utcOffset
            expect(object.createdTime).to.equal new Date(twitterData.created_at).getTime()
