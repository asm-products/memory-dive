    'use strict'

Server module exports method returning new instance of app.

@param {Object} params - compound/express webserver initialization params.
@returns CompoundJS powered express webserver

    app = (params) ->

Specify current dir as default root of server

        params = params or {}
        params.root = params.root or __dirname

        return require('compound').createServer(params)

    module.exports = server = app()
