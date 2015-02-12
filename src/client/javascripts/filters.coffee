angular.module('memoryDiveApp')

    .filter 'monthName', ['$filter', (filter) ->
        dateFilter = filter 'date'
        return (monthNumber) ->
            return dateFilter(new Date(2000, monthNumber), 'MMMM')
    ]

    .filter 'partition', () ->
        cache = {}
        filter = (arr, size) ->
            return if not arr
            newArr = []
            for i in [0..arr.length] by (size)
                newArr.push arr.slice(i, i + size)
            arrString = JSON.stringify(arr)
            fromCache = cache[arrString + size]
            if (JSON.stringify(fromCache) == JSON.stringify(newArr))
                return fromCache
            cache[arrString + size] = newArr
            return newArr
        return filter
