
In this module we setup our CompoundJS app for tests. Nano adapter for JugglingDb doesn't tolerate more than one initialization so we take care of that by keeping a compound app singleton. Most likely this will negatively impact rendering testing but we aren't doing that right now.

    path    = require 'path'
    nock    = require 'nock'
    expect  = (require 'chai').expect
    _       = require 'lodash'
    fs      = require 'fs'
    async   = require 'async'
    debug   = (require 'debug') 'memdive::tests::init'
    nano    = require 'nano'

    compoundSingleton = null

    global.getCompound = (done) ->

        return compoundSingleton if compoundSingleton

        params =
            root: __dirname + '/..'
        server = (require 'compound').createServer params

        server.renderedViews = []
        server.flashedMessages = {}

Monkeypatch compound#render so that it exposes the rendered view files.

        server._render = server.render
        server.render = (viewName, opts, fn) ->
            server.renderedViews.push viewName

Deep-copy flash messages.

            flashes = opts.request.session.flash
            for type in flashes
                server.flashedMessages[type] = []
                for i in flashes[type]
                    server.flashedMessages[type].push flashes[type][i]

            return server._render.apply this, arguments

Check whether a view has been rendered.

        server.didRender = (viewRegex) ->
            didRender = false
            server.renderedViews.forEach renderedView ->
                if renderedView.match viewRegex
                    didRender = true
            return didRender

Check whether a flash has been called.

        server.didFlash = (type) ->
            return !!(server.flashedMessages[type])

Helper methods for working with database.

        server.compound.cleanDbExceptDesignAndUser = (callback) ->
            db = server.compound.couch
            db.list { include_docs: true }, (err, body) ->
                return callback err if err

                docs = []

                docIterator = (row, next) ->
                    return next('row undefined') unless row
                    return next() if row.id.indexOf('_design/') == 0
                    return next() if row.doc and row.doc.model and row.doc.model == 'User'

                    docs.push {
                        _id:        row.id,
                        _rev:       row.value.rev,
                        _deleted:   true
                    }

                    return next()

                docDeleter = (err) ->
                    return callback err if err
                    debug 'deleting ', docs.length, 'docs'
                    db.bulk { docs: docs }, (err) ->
                        return callback err if err
                        callback()

                return async.each body.rows, docIterator, docDeleter

Define helper methods for working with nock.

        # This path is relative to tests
        RESOURCES_TESTS_PATH = '../../../nocks/'

        # Create absolute path
        fs.mkdirSync('nocks') if not fs.existsSync('nocks')

        pathToTestJson = (filename) ->
            return path.join __dirname, RESOURCES_TESTS_PATH, filename

        nockActionIsRecording = (nocksOrFilename) ->
            return false unless _.isString nocksOrFilename
            return false if _.isUndefined process.env.NOCK_RECORDING
            return true if process.env.NOCK_RECORDING == '1'

            enabledFilenames = process.env.NOCK_RECORDING.split(';')
            return _.some enabledFilenames, (enabledFilename) -> enabledFilename == nocksOrFilename

        # If we are recording (NOCL_RECORDING == '1') then we start the recording and return the filename
        # to which we will be saving them.
        # Otherwise, we load the nock definitions from the file and give the user a chance to post-process them.
        server.compound.startNocking = (filename, options) ->

            if nockActionIsRecording filename
                debug 'recording nock requests to', filename
                nock.restore()
                nock.recorder.clear()
                server.compound.recordNocks(options?.recorderOptions)
                return filename
            else
                debug 'reading nock requests from', filename

                defs = server.compound.loadNockDefs filename
                if options and options.preprocessor
                    options.preprocessor defs

                nocks = server.compound.defineNocks defs

                if options and options.postprocessor
                    options.postprocessor nocks

                debug 'tracking', nocks.length, 'nock requests'

                nock.activate() if not nock.isActive()

                return nocks

        server.compound.stopNocking = (nocksOrFilename) ->
            if nockActionIsRecording nocksOrFilename
                debug 'stopped recording nock requests'
                server.compound.dumpRecordedNocks nocksOrFilename
            else
                debug 'stopped tracking nock requests'
                server.compound.nocksDone nocksOrFilename

        server.compound.loadNockDefs = (filename) ->
            defs = nock.loadDefs pathToTestJson filename
            expect(defs).to.exist
            defs

        server.compound.defineNocks = (nockDefs) ->
            expect(nockDefs).to.exist
            nock.define nockDefs

        server.compound.loadNocks = (filename) ->
            nockDefs = server.compound.loadNockDefs filename
            server.compound.defineNocks nockDefs

        server.compound.nocksDone = (nocks) ->
            _.each nocks, (nock) ->
                nock.done()

        server.compound.recordNocks = (options) ->
            clonedOptions = _.clone options or {}
            clonedOptions.dont_print = true
            clonedOptions.output_objects = true
            nock.recorder.rec clonedOptions

        server.compound.dumpRecordedNocks = (filename) ->
            # Stop recording requests
            nock.restore()
            # Format output JSON for easier reading
            recordedNocksJson = (JSON.stringify nock.recorder.play()).replace /{"scope"/g, '\n\r{"scope"'
            if not filename
                console.log recordedNocksJson
            else
                fs.writeFileSync pathToTestJson(filename), recordedNocksJson
            # Clear the recorder requests
            nock.recorder.clear()

        server.compound.consistencyTimeout = (fn) ->
            if not process.env.NOCK_RECORDING
                fn()
            else
                debug 'We wait because db sometimes needs time to reach consistency'
                setTimeout ->
                    debug 'Continuing after the wait'
                    fn()
                , 2000

        compoundSingleton = server.compound
        return compoundSingleton
