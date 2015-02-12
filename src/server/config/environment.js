
var debug = require('debug')('memdive::environment');
var fs = require('fs');

module.exports = function (compound) {

    var express = require('express');
    var crypto = require('crypto');
    var app = compound.app;
    var jsend = require('express-jsend');

    //  Add lodash to app.locals so that it can be used in views
    //      and to controller extension so that it can be used in controllers.
    app.locals._ = compound.controllerExtensions._ = require('lodash');
    app.locals.viewDebug = require('debug')('memdive::views');

    //  Add moment to apps.locals to that it can be used in views.
    app.locals.moment = require('moment');

    //  TODO: Move this code to a separate module.
    compound.controllerExtensions.redirectError = function(code, additionalInfo, redirectUrl) {

        console.error('ERROR', (new Date()).toISOString(), additionalInfo);

        if(!redirectUrl) {
            this.res.status(500).jerror({ error: code, info: additionalInfo });
        } else {
            this.res.redirect(redirectUrl + '?code=' + code + '&description=' + JSON.stringify(additionalInfo));
        }

    };

    //  We intercept requests without extension and add them .html
    //  if the files for those requests exist. This allows us to serve
    //  things like "/tos" without creating a "/tos/index.html" or similar.
    //  As seen here: http://stackoverflow.com/questions/16895047/any-way-to-serve-static-html-files-from-express-without-the-extension
    var addHtmlExtensionMiddleware = function(publicDir) {
        var middleware = function(req, res, next) {
            if(req.path.indexOf('.') !== -1) {
                next();
                return;
            }

            //  Check that the file actually exist.
            var file = publicDir + req.path + '.html';
            fs.exists(file, function(exists) {
                if (exists) {
                    req.url += '.html';
                }
                next();
            });
        };

        return middleware;
    };

    /* jshint -W071 */
    app.configure(function(){
        debug('Configuring app');

        var publicDir = app.root + '/../../_public';

        app.use(addHtmlExtensionMiddleware(publicDir));
        app.use(express.static(publicDir, { maxAge: 86400000 }));
        app.set('jsDirectory', '/js/');
        app.set('cssDirectory', '/css/');
        app.set('cssEngine', 'stylus');
        compound.loadConfigs(__dirname);
        app.use(express.urlencoded());
        app.use(express.json());
        app.use(express.cookieParser(process.env.MEMORY_DIVE_COOKIE_SECRET));
        app.use(require('connect-flash')());

//  Instead of using bodyparser middleware we specify json and urlenconded
//  thus skipping multipart middleware as recommended [here](http://expressjs.com/api.html)

        app.use(express.json());
        app.use(express.urlencoded());

//  Session handling. We use IronCache as latest measurements (2014-08-02) put IronCache way ahead
//  of Cloudant and Orchestrate.IO in speed of response when going from Heroku.
//  Besides, Cloudant is much more expensive for this kind of use (and we already had a surge
//  in charges simply due to frequent sessions)

        app.use(express.session({
            secret: process.env.MEMORY_DIVE_SESSION_SECRET,
            // store: new (require('connect-couchdb')(express))({
            //     uri: process.env.MEMORY_DIVE_COUCHDB_SESSIONS_STORE_URL,
            //     reapInterval: 24 * 60 * 60 * 1000 /* one day */,
            //     compactInterval: 24 * 60 * 60 * 1000 /* one day */
            // }),
            key: 'sid',
            store:  new (require('connect-ironcache')(express))({
                oauthToken: process.env.MEMORY_DIVE_IRON_IO_TOKEN,
                projectID:  process.env.MEMORY_DIVE_IRON_IO_PROJECT_ID,
                cacheID:    'sessions'
            })
        }));

        app.use(express.methodOverride());
        app.use(app.router);
    });

};
