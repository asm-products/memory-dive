
'use strict';

//  Wrapper function to avoid polluting global namespace.
(function() {

    var memoryDiveApp = angular.module('memoryDiveApp');

    memoryDiveApp.controller('TitleCtrl', ['$scope', function($scope) {
        $scope.title = 'Memory Dive';
    }]);

    memoryDiveApp.controller('ErrorCtrl', ['$scope', '$http', '$routeParams', function ($scope, $http, $routeParams) {

        $scope.code = $routeParams.code || 500;
        $scope.description = $routeParams.description || "Something has gone so terribly wrong that we don't even know enough to tell you what happened!";

    }]);

})();
