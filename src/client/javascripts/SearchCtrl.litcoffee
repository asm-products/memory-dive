
# Search controller

    "use strict"

    angular.module('memoryDiveApp').controller "SearchCtrl", [
        "$rootScope"
        "$scope"
        "$http"
        '$routeParams'
        "$log"
        "$window"
        "MainService"
        ($rootScope, $scope, $http, $routeParams, $log, $window, mainService) ->

            $http({
                method: 'GET'
                url:    '/1/api/user/' + $scope.userId + '/search/text'
                params:
                    q:  'text:' + $routeParams.query
            }).success((response) ->
                if response.status != 'success'
                    # TODO: show banner
                    return
                $scope.searchData =
                    query:  $routeParams.query
                    events: response?.data?.docs or []
            ).error((data, status) ->
                $log.error status, data
                # TODO: Show banner
            )
    ]
