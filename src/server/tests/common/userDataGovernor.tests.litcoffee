
    expect = (require 'chai').expect
    _ = require('lodash')
    frugal  = require 'frugal-couch'
    debug = (require 'debug') 'memdive::common::userDataGovernor::tests'

    compound = null
    User = null
    FacebookObject = null
    testUser = null
    governor = null
    userData =
        facebookId: '12345'
        utcOffset:  1 * 60 * 60 * 1000  #   UTC+1
    providerData = null

    describe 'userDataGovernor module', ->
        this.timeout 600000

        init = (done) ->
            User = compound.models.User
            expect(User).to.exist
            FacebookObject = compound.models.FacebookObject
            expect(FacebookObject).to.exist
            governor = compound.common.userDataGovernor

            done()

        before (done) ->
            compound = getCompound()
            expect(compound).to.exist
            if compound.memoryDiveReady
                return init done
            compound.on 'memoryDiveReady', ->
                return init done

        beforeEach (done) ->
            nocks = compound.startNocking 'common__data__userDataGovernor.beforeEach.json'

            compound.consistencyTimeout ->
                compound.couch.cleanDb (err) ->
                    return done err if err

                    testData = JSON.parse((require 'fs').readFileSync 'src/server/tests/fixtures/userDataGovernor.test.json')

                    testDocs = _(testData.rows)
                        .map('doc')
                        .filter (doc) ->
                            return doc._id.indexOf('_design') != 0
                        .value()

                    debug 'prepared', testDocs.length, 'test docs'

                    frugal.overwriteBulk compound.couch, testDocs, (err, res) ->
                        debug 'bulk uploaded', testDocs.length, 'test docs'

                        expect(err).to.not.exist
                        expect(_(res).filter((ret) -> return ret.error).value()).to.be.empty

                        compound.consistencyTimeout ->
                            User.findOrCreate userData, (err, dbUser) ->
                                compound.stopNocking nocks
                                expect(err).to.not.exist
                                expect(dbUser).to.exist
                                testUser = dbUser
                                done()

        describe 'has updateUtcOffset', ->
            it 'that correctly updates utcOffsets of all user objects', (done) ->

                nocks = compound.startNocking 'common__data__userDataGovernor.1.json'

                # Update all docs.
                testUser.utcOffset = -5 * 60 * 60 * 1000
                governor.updateUtcOffset testUser, (err) ->
                    return done err if err

                    # Verify that the docs have been updated.
                    compound.consistencyTimeout ->
                        FacebookObject.all (err, items) ->
                            compound.stopNocking nocks
                            return done err if err

                            expect(items).to.exist
                            items = _.filter items, (item) -> item.userId == testUser.id
                            expect(items.length).to.equal 5
                            expect(_.all items, (item) ->
                                item.type == 'video' and item.utcOffset == testUser.utcOffset
                            ).to.be.true
                            done()

        describe 'has searchUserText function', ->
            it 'that searches for docs matching the given text', (done) ->

                nocks = compound.startNocking 'common__data__userDataGovernor.2.json'

                governor.searchUserText testUser, 'text:test', (err, docs, bookmark) ->
                    compound.stopNocking nocks
                    return done err if err

                    expect(docs).to.be.ok
                    expect(docs.length).to.equal 1
                    doc = _.first(docs)
                    expect(doc.userId).to.equal testUser.id
                    expect(doc.modelId).to.equal '3105870127649'
                    expect(bookmark).to.be.ok
                    done()

        describe 'on getDayData', ->
            it 'returns empty when there is no data for a specific month/day', (done) ->
                nocks = compound.startNocking 'common__data__userDataGovernor.7.json'

                # We know that there are no videos for October 27th for the test user.
                testUser.getDayData new Date(2014, 9, 27), (err, data) ->
                    compound.stopNocking nocks
                    return done err if err
                    expect(data).to.exist
                    expect(data).to.be.an.array
                    expect(data).to.be.empty
                    done()

            it 'returns correct data for a specific month/day', (done) ->
                nocks = compound.startNocking 'common__data__userDataGovernor.8.json'

                # We know that there are videos for October 28th for the test user
                # although not for 2014.
                testUser.getDayData new Date(2014, 9, 28), (err, data) ->
                    compound.stopNocking nocks
                    return done err if err
                    expect(data).to.exist
                    expect(data).to.be.an.array
                    expect(data.length).to.be.equal 1
                    doc = _.first(data)
                    expect(doc).to.be.ok
                    expect(doc.model).to.equal 'FacebookObject'
                    expect(doc.type).to.equal 'video'
                    expect(doc.modelId).to.be.ok
                    done()

        # Note that the comparison is done in the current timezone.
        # TODO: Make the comparison in the *user's* timezone.
        dayObjectEqualToDate = (lhs, rhs) ->
            return lhs.month == rhs.getUTCMonth() + 1 and lhs.day == rhs.getUTCDate()

        describe 'on getNextUserDataDay', ->
            it 'returns error on bad input data', (done) ->

                nocks = compound.startNocking 'common__data__userDataGovernor.9.json'

                testUser.getNextUserDataDay undefined, (err, result) ->
                    compound.stopNocking nocks
                    expect(err).to.exist
                    expect(err.message).to.exist
                    expect(err.message).to.be.equal 'invalid input params'
                    expect(result).to.not.exist
                    done()

            it 'returns correct data', (done) ->
                nocks = compound.startNocking 'common__data__userDataGovernor.10.json'

                # We know the dates of the videos for the test user.
                dates = [new Date(Date.UTC(2014, 0, 1)), new Date(Date.UTC(2012, 0, 18)), new Date(Date.UTC(2009, 9, 28)), new Date(Date.UTC(2009, 11, 15)), new Date(Date.UTC(2011, 11, 28)), new Date(Date.UTC(2011, 11, 30))];
                dateIndex = 0;

                next = ->
                    date = dates[dateIndex];
                    ++dateIndex;
                    console.log date
                    testUser.getNextUserDataDay date, (err, nextDay) ->
                        console.log err, nextDay
                        if dateIndex == dates.length
                            compound.stopNocking nocks
                            expect(nextDay).to.be.null
                            done()
                        else
                            expect(nextDay).to.be.an 'object', 'iteration ' + dateIndex + ' failed'
                            expect(dayObjectEqualToDate(nextDay, dates[dateIndex])).to.be.equal true, 'iteration ' + dateIndex + ' failed (' + JSON.stringify(nextDay) + ' !== ' + dates[dateIndex].getTime() + ')'
                            next()

                # Start iterating              
                next()

        describe 'on getPreviousUserDataDay', ->
            it 'returns error on bad input data', (done) ->
                nocks = compound.startNocking 'common__data__userDataGovernor.11.json'

                testUser.getPreviousUserDataDay undefined, (err, result) ->
                    compound.stopNocking nocks
                    expect(err).to.exist
                    expect(err.message).to.exist
                    expect(err.message).to.be.equal 'invalid input params'
                    expect(result).to.not.exist
                    done()

            it 'returns correct data', (done) ->
                nocks = compound.startNocking 'common__data__userDataGovernor.12.json'

                # We know the dates of the videos for the test user.
                dates = [new Date(Date.UTC(2014, 11, 31)), new Date(Date.UTC(2011, 11, 30)), new Date(Date.UTC(2011, 11, 28)), new Date(Date.UTC(2009, 11, 15)), new Date(Date.UTC(2009, 9, 28)), new Date(Date.UTC(2012, 0, 18))]
                dateIndex = 0;

                next = ->
                    date = dates[dateIndex];
                    ++dateIndex;
                    testUser.getPreviousUserDataDay date, (err, prevDay) ->
                        if dateIndex == dates.length
                            compound.stopNocking nocks
                            expect(prevDay).to.be.null
                            done()
                        else
                            expect(prevDay).to.be.an 'object', 'iteration ' + dateIndex + ' failed'
                            expect(dayObjectEqualToDate(prevDay, dates[dateIndex])).to.be.equal true, 'iteration ' + dateIndex + ' failed (' + JSON.stringify(prevDay) + ' !== ' + dates[dateIndex] + ')'
                            next()

                # Start iterating                            
                next()

        describe 'on getCalendarData', ->
            it 'returns correct data for test user', (done) ->
                nocks = compound.startNocking 'common__data__userDataGovernor.13.json'

                # We know the dates of the videos for the test user.
                testUser.getCalendarData (err, calendarData) ->
                    compound.stopNocking nocks
                    return done err if err
                    expect(calendarData).to.be.ok
                    expect(calendarData).to.be.an.array
                    expect(calendarData.length).to.equal 5
                    expect(_.isEqual(calendarData[0], { month: 1, day: 18, count: 1, FacebookObject: 1 })).to.be.true
                    expect(_.isEqual(calendarData[1], { month: 10, day: 28, count: 1, FacebookObject: 1 })).to.be.true
                    expect(_.isEqual(calendarData[2], { month: 12, day: 15, count: 1, FacebookObject: 1 })).to.be.true
                    expect(_.isEqual(calendarData[3], { month: 12, day: 28, count: 1, FacebookObject: 1 })).to.be.true
                    expect(_.isEqual(calendarData[4], { month: 12, day: 30, count: 1, FacebookObject: 1 })).to.be.true
                    done()

            it 'returns correct data for more than one test user', (done) ->
                nocks = compound.startNocking 'common__data__userDataGovernor.18.json'

                # We know the dates of the videos for the test user.
                testUser.getCalendarData (err, calendarData) ->
                    return done err if err
                    expect(calendarData).to.be.ok
                    expect(calendarData).to.be.an.array
                    expect(calendarData.length).to.equal 5

                    # Create the other user.
                    otherUserData =
                        facebookId: '67890'
                        utcOffset:  1 * 60 * 60 * 1000  #   UTC+1
                    User.findOrCreate otherUserData, (err, otherUser) ->
                        expect(err).to.not.exist
                        expect(otherUser).to.exist

                        # Other user should have different calendar.
                        otherUser.getCalendarData (err, calendarData) ->
                            return done err if err
                            expect(calendarData).to.be.ok
                            expect(calendarData).to.be.an.array
                            expect(calendarData.length).to.equal 5

                            # And this shouldn't have changed.
                            testUser.getCalendarData (err, calendarData) ->
                                compound.stopNocking nocks
                                return done err if err
                                expect(calendarData).to.be.ok
                                expect(calendarData).to.be.an.array
                                expect(calendarData.length).to.equal 5

                                done()
