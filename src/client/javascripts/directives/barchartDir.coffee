angular.module('memoryDiveApp').directive 'barchart', ['$log', '$http', '$q', '$cacheFactory', '$timeout', ($log, $http, $q, $cacheFactory, $timeout) ->
  link = (scope, elem, attrs) ->
    initBar = (elem, data) ->
      scope.morris = Morris.Bar(
        element: elem
        data: data.data
        xkey: data.xkey
        ykeys: data.ykeys
        labels: data.labels
        stacked: if data.stacked then true else null
        ymax: if data.ymax then data.ymax else 'auto'
        hideHover: 'auto'
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
