angular.module('memoryDiveApp').directive 'areachart', ['$log', '$http', '$q', '$cacheFactory', '$timeout', ($log, $http, $q, $cacheFactory, $timeout) ->
  link = (scope, elem, attrs) ->
    initBar = (elem, data) ->
      scope.morris = Morris.Area(
        element: elem
        data: data.data
        xkey: data.xkey
        ykeys: data.ykeys
        labels: data.labels
        ymax: if data.ymax then data.ymax else 'auto'
        hideHover: 'auto'
        behaveLikeLine: if data.behaveLikeLine then true else null
      )

    showNoData = (elem) ->
      $(elem).html "<h5>Waiting for more data</h5>"

    if scope.chartdata?
      scope.morris = initBar elem, scope.chartdata
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
          scope.morris = initBar elem, newData


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
