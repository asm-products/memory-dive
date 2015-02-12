
    expect = (require 'chai').expect
    _ = require 'lodash'

    compound = null
    tracker = null
    EventModel = null
    testUser =
        id: '2014-08-03'

    describe 'tracker module', ->
        this.timeout 100000

        before (done) ->
            compound = getCompound()
            expect(compound).to.exist
            if compound.memoryDiveReady
                return init done
            compound.on 'memoryDiveReady', ->
                return init done

        init = (done) ->
            tracker = compound.common.tracker
            expect(tracker).to.exist
            EventModel = compound.models.Event
            expect(EventModel).to.exist
            done()

        it 'userSignedUp function creates new signed up event in the database', (done) ->
            nocks = compound.startNocking 'common__data__tracker.1.json'
            tracker.userSignedUp testUser, (error, event) ->
                return done(error) if error
                expect(event).to.exist
                expect(event.id).to.exist

                compound.consistencyTimeout ->
                    EventModel.findOne { where: id: event.id }, (error, dbEvent) ->
                        compound.stopNocking nocks
                        return done(error) if error
                        expect(dbEvent).to.exist
                        expect(dbEvent.id).to.equal event.id
                        expect(dbEvent.type).to.equal event.type
                        expect(dbEvent.timestamp).to.equal event.timestamp
                        done()

        it 'userSignedIn function creates new signed up event in the database', (done) ->
            nocks = compound.startNocking 'common__data__tracker.2.json'
            tracker.userSignedIn testUser, (error, event) ->
                return done(error) if error
                expect(event).to.exist
                expect(event.id).to.exist

                compound.consistencyTimeout ->
                    EventModel.findOne { where: id: event.id }, (error, dbEvent) ->
                        compound.stopNocking nocks
                        return done(error) if error
                        expect(dbEvent).to.exist
                        expect(dbEvent.id).to.equal event.id
                        expect(dbEvent.type).to.equal event.type
                        expect(dbEvent.timestamp).to.equal event.timestamp
                        done()

        it 'userSignedOut function creates new signed up event in the database', (done) ->
            nocks = compound.startNocking 'common__data__tracker.3.json'
            tracker.userSignedOut testUser, (error, event) ->
                return done(error) if error
                expect(event).to.exist
                expect(event.id).to.exist

                compound.consistencyTimeout ->
                    EventModel.findOne { where: id: event.id }, (error, dbEvent) ->
                        compound.stopNocking nocks
                        return done(error) if error
                        expect(dbEvent).to.exist
                        expect(dbEvent.id).to.equal event.id
                        expect(dbEvent.type).to.equal event.type
                        expect(dbEvent.timestamp).to.equal event.timestamp
                        done()
