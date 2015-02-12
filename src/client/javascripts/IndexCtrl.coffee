angular.module('memoryDiveApp').controller 'IndexCtrl', ['$scope', '$http', '$log', '$window', '$filter', ($scope, $http, $log, $window, $filter) ->
  $scope.donutData         = undefined
  $scope.lastMonthsData    = undefined
  $scope.totalsByMonthData = undefined
  $scope.totalsByYearData  = undefined

  loadStats = ->
    $http.get '/1/api/user/' + $scope.userId + '/stats'
      .success (response) ->
        if response.status != 'success'
          # TODO: show banner
          return
        data = response.data or []
        prepareTotalStats data
        prepareLastMonthsStats data
        prepareTotalByMonthStats data
        prepareByYearStats data
      .error (data, status) ->
        $log.error status, data
        # TODO: show banner

  prepareByYearStats = (stats) ->
    firstYear = _.first(stats).year
    lastYear = _.last(stats).year
    models = []
    for year in [firstYear..lastYear]
      models.push
        year: "#{year}"
        Twitter: 0
        Facebook: 0
        Dropbox: 0
        Evernote: 0
        Slack: 0
        Foursquare: 0

    totals = _.reduce stats, (models, yearMonthStats) ->
      i = yearMonthStats.year - firstYear
      models[i].Twitter += (yearMonthStats.TwitterObject or 0)
      models[i].Facebook += (yearMonthStats.FacebookObject or 0)
      models[i].Dropbox += (yearMonthStats.DropboxObject or 0)
      models[i].Evernote += (yearMonthStats.EvernoteObject or 0)
      models[i].Slack += (yearMonthStats.SlackObject or 0)
      models[i].Foursquare += (yearMonthStats.FoursquareObject or 0)
      models[i].Total = models[i].Twitter + models[i].Facebook + models[i].Dropbox + models[i].Evernote + models[i].Slack + models[i].Foursquare
      return models
    , models

    $scope.totalsByYearData =
      data: totals
      xkey: 'year'
      ykeys: ['Twitter','Facebook','Dropbox','Evernote','Slack', 'Foursquare']
      labels: ['Twitter','Facebook','Dropbox','Evernote','Slack', 'Foursquare']
      behaveLikeLine: false # this is stacked for Area chart


  prepareTotalByMonthStats = (stats) ->
    models = []
    for mon in [1..12]
      models.push
        month: mon
        monthName: $filter('date')(new Date(2000, mon-1), 'MMM')
        Twitter: 0
        Facebook: 0
        Dropbox: 0
        Evernote: 0
        Slack: 0
        Foursquare: 0

    totals = _.reduce stats, (models, yearMonthStats) ->
      i = yearMonthStats.month - 1
      models[i].Twitter += (yearMonthStats.TwitterObject or 0)
      models[i].Facebook += (yearMonthStats.FacebookObject or 0)
      models[i].Dropbox += (yearMonthStats.DropboxObject or 0)
      models[i].Evernote += (yearMonthStats.EvernoteObject or 0)
      models[i].Slack += (yearMonthStats.SlackObject or 0)
      models[i].Foursquare += (yearMonthStats.FoursquareObject or 0)
      models[i].Total = models[i].Twitter + models[i].Facebook + models[i].Dropbox + models[i].Evernote + models[i].Slack + models[i].Foursquare
      return models
    , models

    $scope.totalsByMonthData =
      data: totals
      xkey: 'monthName'
      ykeys: ['Twitter','Facebook','Dropbox','Evernote','Slack','Foursquare']
      labels: ['Twitter','Facebook','Dropbox','Evernote','Slack','Foursquare']
      stacked: true


  prepareTotalStats = (stats) ->
    # calulate totals per model
    model = {
      Twitter: 0
      Facebook: 0
      Dropbox: 0
      Evernote: 0
      Slack: 0,
      Foursquare: 0
    }

    totals = _.reduce stats, (model, yearMonthStats) ->
      model.Twitter = model.Twitter + (yearMonthStats.TwitterObject or 0)
      model.Facebook = model.Facebook + (yearMonthStats.FacebookObject or 0)
      model.Dropbox = model.Dropbox + (yearMonthStats.DropboxObject or 0)
      model.Evernote = model.Evernote + (yearMonthStats.EvernoteObject or 0)
      model.Slack = model.Slack + (yearMonthStats.SlackObject or 0)
      model.Foursquare = model.Foursquare + (yearMonthStats.FoursquareObject or 0)
      return model
    , model

    donutData = _.map _.keys(totals), (key) -> return { label: key, value: totals[key] }
    $scope.donutData = _.filter donutData, (obj) -> obj.value > 0

  prepareLastMonthsStats = (stats) ->
    currDate = new Date()
    currDate.setDate 1
    models = []
    for mon in [1..12]
      models.push
        year: currDate.getFullYear()
        month: currDate.getMonth() + 1
      currDate.setMonth(currDate.getMonth() - 1)
    models = models.reverse()

    _.forEach models, (model) ->
      m = _.find stats, (s) ->
        return s.year == model.year and s.month == model.month
      model.Twitter = m?.TwitterObject or 0
      model.Facebook = m?.FacebookObject or 0
      model.Dropbox = m?.DropboxObject or 0
      model.Evernote = m?.EvernoteObject or 0
      model.Slack = m?.SlackObject or 0
      model.Foursquare = m?.FoursquareObject or 0
      model.monthYear = "#{model.month}/#{model.year}"

    $scope.lastMonthsData =
      data: models
      xkey: 'monthYear'
      ykeys: ['Twitter','Facebook','Dropbox','Evernote','Slack','Foursquare']
      labels: ['Twitter','Facebook','Dropbox','Evernote','Slack','Foursquare']
      stacked: true


  loadStats()
  
]