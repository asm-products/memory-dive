
    # authInterceptor factory
    angular.module('memoryDiveApp').factory 'authInterceptor', ['$rootScope', '$q', '$window', '$log', '$cookies', '$injector', ($rootScope, $q, $window, $log, $cookies, $injector) ->
        getAuthService = () ->
            # injected manually to get around circular dependency problem.
            $injector.get 'authService'

        request: (config) ->
            authService = getAuthService()
            deferred = $q.defer()

            checkUserId = (config) ->
                authService.getSession().then(
                    (response) ->
                        $rootScope.user = response and response.data
                        $rootScope.userId = $rootScope.user and $rootScope.user.id
                        config.url = config.url.replace(/undefined/g, $rootScope.userId)
                        deferred.resolve(config)
                    , (reason) ->
                        $log.error reason.status, reason.data
                        deferred.reject(config)
                        return authService.redirectToLogin()                                        
                    )

            if not $rootScope.userId and /\/undefined\//.test(config.url)
                checkUserId(config)
            else
                deferred.resolve(config)

            return deferred.promise

        response: (response) ->
            authService = getAuthService()
            return response || $q.when(response)

        responseError: (response) ->
            authService = getAuthService()
            # we can also handle other erorrs, like 5xx errors in order to show the erorr message
            if response.status == 401
                # we can do something else, except logout the user
                # for example, we can let only /web/auth/signout to signout on 401, but for other paths, we can redirect to the error page with message
                # if response.config.url != '/web/auth/signout'
                #   meta:redirectToErrorPageWithAdded back url
                authService.redirectToLogin()
            return $q.reject(response)
    ]
