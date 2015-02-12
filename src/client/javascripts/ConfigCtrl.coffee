
angular.module('memoryDiveApp').controller 'ConfigCtrl', ['$rootScope', '$scope', '$http', '$log', '$window', ($rootScope, $scope, $http, $log, $window) ->

  $scope.showBackupProviders = false
  $scope.showDataProviders = false

  getProviderData = (id) ->
    switch id
      when 'tw'   then return ['/images/twitter.png', 'Twitter']
      when 'fb'   then return ['/images/facebook.png', 'Facebook']
      when 'dbox' then return ['/images/dropbox.png', 'Dropbox']
      when 'en'   then return ['/images/evernote.png', 'Evernote']
      when 'sl'   then return ['/images/slack.png', 'Slack']
      when 'txt'  then return ['/images/text.png', 'Text']
      when 'gp'   then return ['/images/google_plus.png', 'Google+']
      when '4s'   then return ['/images/foursquare.png', 'Foursquare']
      else return ['/images/question.png', 'Unknown']

  setUserProviderData = (provider) ->
    provider.pictureUrl = provider.pictureUrl or '/images/no_picture.png'
    provider.displayName = provider.displayName or '(no name)'
    [provider.providerPictureUrl, provider.providerName] = getProviderData(provider.providerId)

  collectProviders = (url, callback) ->
    if not callback
      return

    $http.get url
      .success (response) ->
        return callback(response) if response.status != 'success'

        providers = []

        _.forEach response.data, (provider) ->
          setUserProviderData provider
          providers.push provider

        callback(undefined, providers)
      .error (data, status) ->
        callback(data)

  showError = (error) ->
    $log.error error
    # TODO: Show banner

  # Get registered backup providers
  $scope.backupProviders = []
  collectProviders '/1/api/user/' + $scope.userId + '/provider/backup', (error, providers) ->
    return showError error if error
    $scope.backupProviders = providers

  # Get registered data providers
  $scope.dataProviders = []
  collectProviders '/1/api/user/' + $scope.userId + '/provider/data', (error, providers) ->
    return showError error if error
    $scope.dataProviders = providers

  tz = jstz.determine() # Determines the time zone of the browser client
  $scope.currentTimezoneName = tz.name() # Returns the name of the time zone eg "Europe/Berlin"

  $scope.availableBackupProviders = []

  # Load available backup providers on-demand.
  $scope.toggleBackupProviders = ->
    $scope.showBackupProviders = !$scope.showBackupProviders
    if _.isEmpty $scope.availableBackupProviders
      collectProviders '/1/api/user/' + $scope.userId + '/provider/backup/available', (error, providers) ->
        return showError error if error
        $scope.availableBackupProviders = providers

  $scope.availableDataProviders = []

  # Load available data providers on-demand.
  $scope.toggleDataProviders = ->
    $scope.showDataProviders = !$scope.showDataProviders
    if _.isEmpty $scope.availableDataProviders
      collectProviders '/1/api/user/' + $scope.userId + '/provider/data/available', (error, providers) ->
        return showError error if error
        $scope.availableDataProviders = providers

  # We start the OAuth process for the provider with callback URL being this same "page".
  $scope.getOAuthUrl = (provider) ->
    return provider.oauthStartUrl + '?clientCallbackSuccessUrl=/app/config&clientCallbackFailureUrl=/app/error'

  $scope.addBackupProvider = (provider) ->
    $window.location.href = $scope.getOAuthUrl provider

  $scope.addDataProvider = (provider) ->
    $window.location.href = $scope.getOAuthUrl provider

  $scope.startDefineTimezone = ->
    $scope.definingTimezone = true

  $scope.doneDefineTimezone = (newTimezoneName) ->
    $scope.definingTimezone = false

    # Backup the old timezone in the case API call fails.
    oldUserTimezone = $scope.user.timezone
    $scope.user.timezone = newTimezoneName

    revertUserTimezone = ->
      $scope.user.timezone = oldUserTimezone

    # Update the service state.
    $http.post '/1/api/user/' + $scope.userId, { rev: $scope.user.rev, timezone: newTimezoneName }
      .success (response) ->
        if response.status != 'success'
          $log.error response
          revertUserTimezone()
          # TODO: Show banner.
          return
        # Update the user's object revision.
        $scope.user.rev = response.data.rev
      .error (data, status) ->
        revertUserTimezone()
        $log.error status, data
        # TODO: Show banner.

  $scope.cancelDefineTimezone = ->
    $scope.definingTimezone = false

  $scope.deleteBackupProvider = ->
    alert 'Not implemented yet.'

  $scope.deleteDataProvider = ->
    alert 'Not implemented yet.'

]
