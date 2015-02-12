
# Schedule starter

This module is responsible for creating and starting the schedule for all hard-coded jobs in the system.

    debug = (require 'debug') 'memdive::initializers::scheduleStarter'

    module.exports = (compound) ->
        compound.on 'memoryDiveReady', ->

Start recurring schedules for worker process only

            if process.env.MEMORY_DIVE_WORKER
                schedule = require 'node-schedule'

We invoke data refreshing every hour to evenly distribute the load.

                userDataCollectionSchedule = new schedule.RecurrenceRule()
                userDataCollectionSchedule.minute = 0
                userDataCollectionSchedule.hour = 23

                schedule.scheduleJob userDataCollectionSchedule, ->
                    compound.common.scheduler.refreshAllUserInfo (err) ->
                        console.log 'Scheduled data collection failed', err if err

We send user emails at their midnight.

                dailyEmailsSchedule = new schedule.RecurrenceRule()
                dailyEmailsSchedule.minute = 0
                dailyEmailsSchedule.hour = 1

                schedule.scheduleJob dailyEmailsSchedule, ->
                    compound.common.scheduler.sendDailyEmails (err) ->
                        console.log 'Scheduled email sending failed', err if err

We backup data once a day.

                backupSchedule = new schedule.RecurrenceRule()
                backupSchedule.minute = 0
                backupSchedule.hour = 3

                schedule.scheduleJob backupSchedule, ->
                    compound.common.scheduler.backupAllUserDataToAllProviders (err) ->
                        console.log 'Scheduled data backup failed', err if err
