angular.module('memoryDiveApp').directive 'donutchart', ['$log', '$http', '$q', '$cacheFactory', '$timeout', ($log, $http, $q, $cacheFactory, $timeout) ->
  link = (scope, elem, attrs) ->
    initDonut = (elem, data) ->
      Morris.Donut(
        element: elem
        data: scope.chartdata
        resize: true
      )

    showNoData = (elem) ->
      $(elem).html "<h5>Waiting for more data</h5>"

    if scope.chartdata?
      scope.morris = initDonut elem, scope.chartdata
    else
      showNoData elem

    scope.$watch 'chartdata', (newData, oldData) ->
      if not scope.chartdata?
        showNoData elem
      else
        $(elem).find('h5').remove()
        if scope.morris?
          scope.morris.setData newData
        else
          scope.morris = initDonut elem, newData

  return {
    restrict: 'E'
    template: '<div class="text-center"></div>'
    replace: true
    link: link
    scope: {
      chartdata: '='
    }
  }
]
