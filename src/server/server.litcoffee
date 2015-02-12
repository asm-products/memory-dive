
    # make sure we have NODE_ENV
    process.env.NODE_ENV = process.env.NODE_ENV || 'development'

    debug    = require('debug')('memdive::server')
    cluster  = require 'cluster'
    cpuCount = require('os').cpus().length
    fs       = require 'fs'

    jobWorkers = []
    webWorkers = []

    # Setup nodetime profiler.
    if process.env.NODETIME_ACCOUNT_KEY
        require('nodetime').profile({
            accountKey: process.env.NODETIME_ACCOUNT_KEY,
            appName: 'web'
        })

    addWebWorker = ->
        webWorkers.push cluster.fork({MEMORY_DIVE_WEB: 1}).id

    addJobWorker = ->
        jobWorkers.push cluster.fork({MEMORY_DIVE_WORKER: 1}).id

    removeWebWorker = (id) ->
        webWorkers.splice webWorkers.indexOf(id), 1

    removeJobWorker = (id) ->
        jobWorkers.splice jobWorkers.indexOf(id), 1

    if cluster.isMaster
        pidfile = ".server-#{process.env.NODE_ENV}.pid"
        fs.writeFileSync pidfile, process.pid

        # we need at least 2 CPU, one for job, other for web worker
        throw new Error('Not enough CPUs, need at least 2') if cpuCount < 2

Always create a single worker and as many web servers as possible.

        addJobWorker()
        maxWebProcesses = if process.env.MEMORY_DIVE_MAX_WEB_PROCESSES? then process.env.MEMORY_DIVE_MAX_WEB_PROCESSES else 1
        while (cpuCount -= 1) and (maxWebProcesses)
            addWebWorker()
            maxWebProcesses -= 1

        cluster.on 'exit', (worker, code, signal) ->
            if webWorkers.indexOf(worker.id) != -1
                debug 'http worker (pid:%d) died. Trying to respawn...', worker.process.pid
                removeWebWorker worker.id
                addWebWorker()

            if jobWorkers.indexOf(worker.id) != -1
                debug 'job worker (pid:%d) died. Trying to respawn...', worker.process.pid
                removeJobWorker worker.id
                addJobWorker()
    else
        if process.env.MEMORY_DIVE_WEB
            web = require './web'
            debug 'start http server (id:%d, pid:%s)', cluster.worker.id, process.pid
            port = process.env.PORT or 14113
            host = process.env.HOST or '0.0.0.0'
            web.listen port, host, () ->
                console.log 'Compound server listening on %s:%d within %s environment', host, port, web.get('env')

        if process.env.MEMORY_DIVE_WORKER
            worker = require './worker'
            debug 'start job server (id:%d, pid:%s)', cluster.worker.id, process.pid
