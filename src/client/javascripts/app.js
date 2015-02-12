
'use strict';

angular.module('memoryDiveApp', ['ngRoute', 'angular-lodash', 'angular-loading-bar', 'ngAnimate', 'ngCookies'])
    .config(['$routeProvider', 'cfpLoadingBarProvider', '$httpProvider', '$locationProvider', function($routeProvider, cfpLoadingBarProvider, $httpProvider, $locationProvider) {

        $locationProvider.html5Mode(true);

        $httpProvider.interceptors.push('authInterceptor');

        // loading bar configuration
        cfpLoadingBarProvider.includeSpinner = true;
        cfpLoadingBarProvider.includeBar = true;
        cfpLoadingBarProvider.latencyThreshold = 300;

        // routes
        $routeProvider
            .when('/app/index', {
                templateUrl: '/partials/index.html',
                controller: 'IndexCtrl'
            })
            .when('/app/calendar', {
                templateUrl: '/partials/calendar.html',
                controller: 'CalendarCtrl'
            })
            .when('/app/calendar/:month/:day', {
                templateUrl: '/partials/day.html',
                controller: 'DayCtrl'
            })
            .when('/app/config', {
                templateUrl: '/partials/config.html',
                controller: 'ConfigCtrl'
            })
            .when('/app/signout', {
                templateUrl: '/partials/signOut.html',
                controller: 'SignOutCtrl'
            })
            .when('/app/search/:query', {
                templateUrl: '/partials/search.html',
                controller: 'SearchCtrl'
            })
            .when('/app/error', {
                templateUrl: '/partials/error.html',
                controller: 'ErrorCtrl'
            })
            .otherwise({
                redirectTo: '/app/index'
            });

}]);
