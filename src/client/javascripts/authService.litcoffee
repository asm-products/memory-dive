
    angular.module('memoryDiveApp').factory 'authService', ['$window', '$log', '$cookies', '$http', '$q', ($window, $log, $cookies, $http, $q) ->
        getToken: ->
            token = $cookies.token
            if token
                $window.localStorage.token = token
                delete $cookies['token']
            token = $window.localStorage.token

        clearToken: ->
            delete $cookies['token']
            delete $window.localStorage['token']

        redirectToLogin: ->
            $window.location.href = '/landing?r=' + encodeURIComponent($window.location.href)

        signout: (id) ->
            deferred = $q.defer()
            $http.post "1/api/auth/signout"
                .success (response) -> deferred.resolve response
                .error (data, status) -> deferred.reject { data:data, status:status }
            return deferred.promise

        getSession: ->
            deferred = $q.defer()
            $http.get "/1/api/auth/session"
                .success (response) -> deferred.resolve response
                .error (data, status) -> deferred.reject { data:data, status:status }
            return deferred.promise

    ]
