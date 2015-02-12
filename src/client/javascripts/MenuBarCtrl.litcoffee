
# Menu bar controller

    "use strict"

    angular.module("memoryDiveApp").controller "MenuBarCtrl", [
        "$rootScope"
        "$scope"
        "$http"
        "$log"
        "$window"
        "$location"
        "MainService"
        ($rootScope, $scope, $http, $log, $window, $location, mainService) ->

            $scope.signout = ->
                $scope.signOutDisplayName = $rootScope.user.displayName
                delete $rootScope.userId
                delete $rootScope.user

                $http.put "/1/api/auth/signout"

                $location.path '/app/signout'

            $scope.search = (searchQuery) ->
                $location.path("/app/search/" + encodeURIComponent(searchQuery))
    ]
