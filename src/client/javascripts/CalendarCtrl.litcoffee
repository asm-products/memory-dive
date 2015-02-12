
# Calendar controller

    angular.module("memoryDiveApp").controller "CalendarCtrl", [
        "$rootScope"
        "$scope"
        "$routeParams"
        "$http"
        "$window"
        "$log"
        ($rootScope, $scope, $routeParams, $http, $window, $log) ->

When there is no userId we redirect the browser to landing page.

TODO: Redirect to error rendering.

            $scope.calendar = {}

API returns sparse data, not all days (as it doesn't return days for which there is no data)
So we process the received data so that we have all possible dates in the UI.
This orders the data in [months][days] matrix with received day data in each cell.

TODO: Redirect to error rendering.

            $http.get("/1/api/user/" + $scope.userId + "/calendar").success((response) ->
                return if response.status isnt "success"
                $scope.calendar = processCalendarResponseData(response.data)
            ).error (data, status) ->
                $log.error status, data

            processCalendarResponseData = (days) ->

                generateEmptyCalendarData = ->

                    data = []

                    generateMonthData = (month, numberOfDays) ->
                        monthData = []
                        i = 1

                        while i <= numberOfDays
                            monthData[i] =
                                month: month
                                day: i
                                count: 0
                            ++i
                        return monthData

                    data[0] = generateMonthData(0, 31)
                    data[1] = generateMonthData(1, 29)
                    data[2] = generateMonthData(2, 31)
                    data[3] = generateMonthData(3, 30)
                    data[4] = generateMonthData(4, 31)
                    data[5] = generateMonthData(5, 30)
                    data[6] = generateMonthData(6, 31)
                    data[7] = generateMonthData(7, 31)
                    data[8] = generateMonthData(8, 30)
                    data[9] = generateMonthData(9, 31)
                    data[10] = generateMonthData(10, 30)
                    data[11] = generateMonthData(11, 31)

                    return data

JavaScript months start from *zero* (while days start from 1... go figure that one out)
so we adjust months by adding 1 when returning previous/next days.

                CRAZY_ASS_JAVASCRIPT_MONTH_ADJUSTMENT_FACTOR_OF_1 = 1

                calendarData = generateEmptyCalendarData()
                _.each days, (day) ->
                    day.uiUrl = "/app/calendar/" + day.month + "/" + day.day
                    calendarData[day.month - CRAZY_ASS_JAVASCRIPT_MONTH_ADJUSTMENT_FACTOR_OF_1][day.day] = day

                return calendarData
    ]
