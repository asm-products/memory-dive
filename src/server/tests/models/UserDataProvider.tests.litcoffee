    expect = (require 'chai').expect
    _ = require 'lodash'

    compound = null
    UserDataProvider = null

    describe 'UserDataProvider model', ->
        this.timeout 150000

        before (done) ->

            compound = getCompound()
            expect(compound).to.exist
            if compound.memoryDiveReady
                return init done
            compound.on 'memoryDiveReady', ->
                return init done

        init = (done) ->
            UserDataProvider = compound.models.UserDataProvider
            expect(UserDataProvider).to.exist
            done()

        beforeEach (done) ->
            nocks = compound.startNocking 'models__data__UserDataProvider.beforeEach.json'
            compound.couch.cleanDb (err) ->
                return done err if err
                compound.stopNocking nocks
                done()

        it 'put creates new provider', (done) ->

            nocks = compound.startNocking 'models__data__UserDataProvider.1.json'

            data =
                userId: 'whatever-id'
                providerId: 'twitter'
                providerUserId: '123'
                providerData:
                    token: 'whatever'

            UserDataProvider.putUserProvider data, (error) ->
                expect(error).to.be.null

                UserDataProvider.getUserProvider data.userId, data.providerId, data.providerUserId, (error, dbProvider) ->
                    expect(error).to.be.null
                    expect(dbProvider).to.be.ok
                    expect(dbProvider.userId).to.equal 'whatever-id'
                    expect(dbProvider.providerId).to.equal data.providerId
                    expect(dbProvider.providerUserId).to.equal data.providerUserId
                    expect(dbProvider.providerData).to.be.ok
                    expect(dbProvider.providerData).to.have.property 'token'
                    expect(dbProvider.providerData.token).to.equal data.providerData.token
                    compound.stopNocking nocks
                    done()

        it 'put updates provider', (done) ->

            nocks = compound.startNocking 'models__data__UserDataProvider.2.json'

            data =
                userId: 'whatever-id'
                providerId: 'twitter'
                providerUserId: '123'
                providerData:
                    token: 'whatever'

            UserDataProvider.putUserProvider data, (error) ->
                expect(error).to.be.null

                delete data.providerData.token
                data.providerData.noToken = 'notWhatever'

                UserDataProvider.putUserProvider data, (error) ->
                    expect(error).to.be.null

                    UserDataProvider.getUserProviders data.userId, (error, providers) ->
                        expect(error).to.be.null
                        expect(providers).to.be.ok
                        expect(providers).to.be.an.array
                        expect(providers.length).to.equal 1

                        UserDataProvider.getUserProvider data.userId, data.providerId, data.providerUserId, (error, dbProvider) ->
                            expect(error).to.be.null
                            expect(dbProvider).to.be.ok
                            expect(dbProvider.userId).to.equal data.userId
                            expect(dbProvider.providerId).to.equal data.providerId
                            expect(dbProvider.providerData).to.be.ok
                            expect(dbProvider.providerData).to.have.property 'noToken'
                            expect(dbProvider.providerData.noToken).to.equal data.providerData.noToken
                            compound.stopNocking nocks
                            done()

        it 'gets all user providers', (done) ->

            nocks = compound.startNocking 'models__data__UserDataProvider.3.json'

            twitterData =
                userId: 'whatever-id'
                providerId: 'twitter'
                providerUserId: '456'
                providerData:
                    token: 'whatever'

            facebookData =
                userId: 'whatever-id'
                providerId: 'facebook'
                providerUserId: '123'
                providerData:
                    token: 'whatever'

            UserDataProvider.putUserProvider twitterData, (error) ->
                expect(error).to.be.null

                UserDataProvider.putUserProvider facebookData, (error) ->
                    expect(error).to.be.null

                    UserDataProvider.getUserProviders 'whatever-id', (error, providers) ->
                        expect(error).to.be.null
                        expect(providers).to.be.ok
                        expect(providers).to.be.an.array
                        expect(providers.length).to.equal 2
                        compound.stopNocking nocks
                        done()

        it 'gets user associated provider data', (done) ->

            nocks = compound.startNocking 'models__data__UserDataProvider.4.json'

            twitterData =
                userId: 'whatever-id'
                providerId: 'twitter'
                providerUserId: '123'
                providerData:
                    token:  'whatever'

            facebookData =
                userId: 'whatever-id'
                providerId: 'facebook'
                providerUserId: '456'
                providerData:
                    token: 'whatever'

            UserDataProvider.putUserProvider twitterData, (error) ->
                expect(error).to.be.null

                UserDataProvider.putUserProvider facebookData, (error) ->
                    expect(error).to.be.null

                    UserDataProvider.getUserProvider facebookData.userId, facebookData.providerId, facebookData.providerUserId, (error, data) ->
                        expect(error).to.be.null
                        expect(data).to.be.ok
                        expect(data.token).to.equal facebookData.token
                        compound.stopNocking nocks
                        done()

        it 'errors on internal inconsistencies', (done) ->

            nocks = compound.startNocking 'models__data__UserDataProvider.5.json'

            twitterData =
                userId: 'whatever-id'
                providerId: 'twitter'
                providerUserId: 'test'
                providerData:
                    token:  'whatever'

            o1 = UserDataProvider.createObject twitterData
            o1.save (err) ->
                return done err if err

                o2 = UserDataProvider.createObject twitterData
                o2.save (err) ->
                    compound.stopNocking nocks
                    expect(err).to.exist
                    expect(err.toString()).to.equal 'Error: Document update conflict.'
                    done()

        it 'put creates and updates provider even with numerical providerUserId', (done) ->

            nocks = compound.startNocking 'models__data__UserDataProvider.7.json'

            data =
                userId: 'whatever-id'
                providerId: 'twitter'
                providerUserId: 123456
                providerData:
                    token: 'whatever'

            UserDataProvider.putUserProvider data, (error) ->
                expect(error).to.be.null

                delete data.providerData.token
                data.providerData.noToken = 'notWhatever'

                UserDataProvider.putUserProvider data, (error) ->
                    expect(error).to.be.null

                    UserDataProvider.getUserProviders data.userId, (error, providers) ->
                        expect(error).to.be.null
                        expect(providers).to.be.ok
                        expect(providers).to.be.an.array
                        expect(providers.length).to.equal 1

                        UserDataProvider.getUserProvider data.userId, data.providerId, data.providerUserId, (error, dbProvider) ->
                            expect(error).to.be.null
                            expect(dbProvider).to.be.ok
                            expect(dbProvider.userId).to.equal data.userId
                            expect(dbProvider.providerId).to.equal data.providerId
                            expect(dbProvider.providerData).to.be.ok
                            expect(dbProvider.providerData).to.have.property 'noToken'
                            expect(dbProvider.providerData.noToken).to.equal data.providerData.noToken
                            compound.stopNocking nocks
                            done()
