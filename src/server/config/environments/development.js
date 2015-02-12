'use strict';

var _ = require('lodash');

module.exports = function (compound) {
    var app = compound.app;

    app.configure('development', function() {
        console.log('Configuring app for development');

        app.enable('watch');
        app.enable('log actions');
        app.enable('env info');
        //  Force assets compilation restarts node when working with nodemon
        //  TODO: Fix nodemon as it seems to be a POS.
        //app.enable('force assets compilation');
        app.set('translationMissing', 'display');
        //  We don't use express.errorHandler middleware as it can lead to race conditions on res.send
        //  when rendering errors as HTTP and in combination with session saving on memory provider.
        //  User our own middleware for error handling as it acts synchronously and sends the 500
        //  immediately.
        app.use(function(error, req, res, next) {
            //  Handle server errors by sending 500.
            if(!error) {
                next();
            } else {
                console.error(error.stack);
                res.redirect('/error/500');
            }
        });
    });
};
