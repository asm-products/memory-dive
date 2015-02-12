
# Time Lord

## Rationale

This module lords over user time and its zones. The discussion here and rationale I'll give (I hope as right now I have no idea how the time and the zones should be treated) are for future reference.

Time and its passage is essential to the Memory Dive and its users. Here are the possibilities:

## Users should always see the data in the universal time zone

This is only useful to computers (and maybe like 5 human beings total). Imagine this conversation:

- I can't find the photos of all my daughter's birthdays.
- When was your daughter born?
- On April 29th at 23:08.
- Chilean Contiental time zone, right?
- Yes.
- Ok, she was actually born on April 30th at 3:08 Universal TZ.
- So what?
- Well, look for the photos of her birthdays on April 30th.

Yeah, right... That would fly like a plutonium ingot.

## Users should always see the data in their official time zone

This is better - at least it makes sense to their *current* reference and they can always change it. But what if, like me, you have lived over half of your life in a different time zone from the current one. Then what... the events happened on what date exactly: the original time zone or the current time zone? They happened when they happened - no matter what the time zone it was. Forcing them into time zones is not the best option.

## Users should see the data in the dates of the *original* time zone

This is optimal but is also very, very difficult to implement right. Namely, it wouldn't be hard to implement if everybody treated the data in the same way *and* if they included the time zones. But they don't.

So the combination has to be some of the above as the optimal solution is unattainable.

The most reasonable compromise, it seems to me, is:

1. Treat the data you know is "good" (we know the time zone *and* the exact time expressed in that time zone) per its original time zone.
2. All other data treat as if it was made in the current time zone except when you have geo-data that indicates otherwise.
3. The data with associated geo-data treat as if it was made in the geographical time zone (depending on its daylight saving time in effect at that time)
4. Allow users to manually set the actual date and time of every object.

Hence... the Time Lord. Or maybe node-time-lord. Oh... Dr. Who reference? Interesting. I only watched a couple of episodes... I was thinking about Time Bandits. That's not a bad name either.

To implement this I would need the following:

1. Historic record of *all* changes to time zones, both geographical (rare, hopefully) and relative to UTC. There is bound to be a db for this. Right?
2. Mapping of geo-data to time zones *at* the time of the event.

Could this be made simpler? How does FB deal with this?

I actually failed to find out how Facebook deals with it. I guess they just assign their own data to everything that's posted. This is easy for them but not really possible for me.

So... the user time zone is decisive. We will apply its offset during data collection, before its even put into the database. If the time zone ever changes we will change the offset which will re-index all the user's documents.

This is valid even for the items of our own creation or for those items where we know the actual local time they were taken. If we were to treat these items differently than others then we would have out-of-order items or items in different order depending on the time zone of the user. Which is crazy.

But... what should the DST do? DST doesn't change the time zone but it offsets it. There are several choices here:

1. Do nothing. Then all the items from current "time area" will be shown with +1 hour.
2. Adjust all the items for DST.
3. Adjust for DST only the items in current "time area" and those that were affected by DST in the past.

Again... what's least surprising?

1. It would surprise me if I tweeted something and it showed up as +1 hour.
2. It would surprise me if DST change influenced past items and re-shuffled their times (and dates for the items that are in +/- 1 of date line in the user's TZ)

So that leaves the 3rd option: adjust for DST where it was in effect, don't when it wasn't. A module named 'timezone' can help with that provided that we know what was the user's real time zone in the past. We will assume that it was the current time zone and allow them to change.

Conclusion:

1. All users have a current time zone. We have to find a way to convert it to tz database representation.
2. All items are treated as belonging to that time zone and their offsets are calculated during collection.
3. Users can add additional time zones from their past (e.g. I lived in UTC+1 until July 19th 1999 and switched to UTC-3 on July 20th 1999) and these will be applied during collection (or re-applied when changed)

## Implementation

This module will provide functionality of timezone module (and its underlying tz database) to the rest of the system. It will return a correct offset for the given time zone and time.

    tz = require 'timezone'
    _ = require 'lodash'

### Initialization

The module is integrated into CompoundJS application.

    debug = (require 'debug') 'memdive::common::timeLord'

    app = undefined

    module.exports.init = (compound) ->
        compound.on 'ready', (compoundApp) ->
            app = compoundApp

            app.common = app.common or {}
            app.common.timeLord = exports
            app.emit 'timeLordReady'

### Internals

`zonesCache` is an array of time zone modules that have already been loaded by the system.

    zonesCache = []

    getTimezone = (timezone) ->
        try
            zone = zonesCache[timezone] = tz(require('timezone/' + timezone))
            return zone
        catch exception
            console.log 'Invalid time zone', timezone, ':', exception
            return undefined

### Constants

We define Memory Dive epoch as January 1st 2014. This allows us to use the modern timezomes independent of when exactly an event occurred which again allows us to cache the offset in the database.
Alternative: if we ever switch to time relative offset calculation (that is, calculating offset for the date and timezone when an event occurred), we would need to store the timezone offsets data in the database *for each user* and then map/reduce events and timezones.

    MEMORY_DIVE_EPOCH = Date.UTC(2014, 1, 1)

### Exported functions

#### `offset`

`offset` function returns the difference between the given time zone at the `utcEpochTime` POSIX time. If the `utcEpochTime` is not defined, then a fixed MEMORY_DIVE_EPOCH (January 1st 2014) is used as the reference.

    offset = (timezone, utcEpochTime) ->

        utcEpochTime = utcEpochTime or MEMORY_DIVE_EPOCH

Get the timezone from the timezone module.

        zone = getTimezone timezone

If the timezone couldn't be found just return and leave the client to take care of it.

        return zone if _.isUndefined zone

Get the time's components by parsing the output.

        components = zone(utcEpochTime, timezone, '%Y %m %d %H %M %S %N').split(' ').map (c) ->
            return parseInt(c, 10)

The epoch time from the given timezone can be calculated from the components.

        timezoneEpochTime = tz components

Calculate the offset.

        return timezoneEpochTime - utcEpochTime

    module.exports.offset = offset
