
# Day controller

    'use strict'

    angular.module('memoryDiveApp').controller 'DayCtrl', [
        '$rootScope'
        '$scope'
        '$http'
        '$routeParams'
        '$log'
        '$window'
        '$cacheFactory',
        '$location'
        ($rootScope, $scope, $http, $routeParams, $log, $window, $cacheFactory, $location) ->

Create the calendar day cache if it doesn't exist.

            if not $rootScope.calendarDayDataCache
                $rootScope.calendarDayDataCache = $cacheFactory('calendarDayDataCache')

### Helper functions.

            getMonthDayCacheKey = (monthDayObject) ->
                return monthDayObject.month + '/' + monthDayObject.day;

            queryCacheByApiUrl = (apiUrl) ->
                return $rootScope.calendarDayDataCache.get apiUrl

Defines the relativity of the requested calendar day data compared to current browser date.

            CalendarDayDataRelativity =
                Previous: -1
                Exact: 0
                Next: 1

            getCalendarDayData = (url, dayDataRelativity, successCallback, errorCallback) ->

                data = queryCacheByApiUrl(url)
                return successCallback(data) if data

                $http.get(url).success((response) ->
                    if response.status isnt 'success'
                        # TODO: Show banner.
                        return $log.error response

                    dayData = response.data

Group data by year.

                    data = _.groupBy(response.data.events, (event) ->
                        utcOffset = (if event.utcOffset then event.utcOffset else 0)
                        createdTime = (if event.createdTime then event.createdTime else 0)
                        moment(createdTime + utcOffset).utc().format 'YYYY'
                    )

Group year items into 4-item rows.

                    dayData.date = moment().month(dayData.month - 1).date(dayData.day).format('MMMM Do')
                    dayData.years = []
                    createDataRows = (yearData) ->
                        _.compact yearData.map((inner, i) ->
                            yearData.slice i, i + 4 if i % 4 is 0
                        )

                    keys = _.keys(data).reverse()
                    _.forEach keys, (key) ->
                        dayData.years.push
                            year: key
                            rows: createDataRows(data[key])

                    delete dayData.events

We cache the data by both URL and by month/day. This minimizes the number of calls to API
as sometimes we have the URL (when doing prev/next) and sometimes we have month/day (when
arriving to the browser URL)

                    $rootScope.calendarDayDataCache.put url, dayData
                    $rootScope.calendarDayDataCache.put getMonthDayCacheKey(dayData), dayData

And *then* we have this nice trick of caching the current $scope.calendarDay with previous or next URL
depending on the relativity of the new calendar day data. This eliminates all duplicate requests
to service API. So if the user requested the next day the *current* day is the previous day of that
just retrieved next day and vice versa.

                    if $scope.calendarDay
                        switch dayDataRelativity
                            when CalendarDayDataRelativity.Previous
                                $rootScope.calendarDayDataCache.put dayData.nextDayUrl, $scope.calendarDay
                            when CalendarDayDataRelativity.Next
                                $rootScope.calendarDayDataCache.put dayData.prevDayUrl, $scope.calendarDay
                            else
                                # Don't do anything.


Finally we do a look ahead by requesting (in the background) prev/next day data per their URLs
so that all that data is *already* cached if the user requests them. To avoid getting into a chain
of reading prev/next data (e.g. next is read and then requests next and then that request next and
so on forever) we do this only when exact data is being requested.

                    if dayDataRelativity is CalendarDayDataRelativity.Exact
                        setTimeout (->
                            getCalendarDayData dayData.prevDayUrl, CalendarDayDataRelativity.Previous
                            getCalendarDayData dayData.nextDayUrl, CalendarDayDataRelativity.Next
                        ), 0
                    successCallback dayData if successCallback
                ).error (data, status) ->
                    $log.error status, data
                    errorCallback data, status if errorCallback

When loading the data we first try to find in the cache per our $routeParams.
If that is not available we call the service API.

            data = $rootScope.calendarDayDataCache.get(getMonthDayCacheKey($routeParams))
            if data
                $scope.calendarDay = data
            else
                apiUrl = '/1/api/user/' + $scope.userId + '/calendar/' + $routeParams.month + '/' + $routeParams.day
                getCalendarDayData apiUrl, CalendarDayDataRelativity.Exact, ((data) ->
                    $scope.calendarDay = data
                ), (data, status) ->
                    # TODO: Show banner.
                    $log.error data, status

### Functions to retrieve data from previous and next days.

            getOtherDayData = (url, dayDataRelativity) ->

In the background start fetching the data.

                getCalendarDayData url, dayDataRelativity, ((dayData) ->

On success we change the browser location to the new day.
The data is already cached per month/day so it won't be reloaded from the service.

                    $location.path('/app/calendar/' + dayData.month + '/' + dayData.day)
                    return
                ), (data, status) ->

                    #  Show banner.
                    $log.error data, status

            $scope.getPrevDayData = (url) ->
                getOtherDayData url, CalendarDayDataRelativity.Previous

            $scope.getNextDayData = (url) ->
                getOtherDayData url, CalendarDayDataRelativity.Next
    ]
