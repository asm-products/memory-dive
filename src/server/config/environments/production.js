
'use strict';

module.exports = function (compound) {
    var app = compound.app;

    app.configure('production', function() {
        console.log('Configuring app for production');

        app.enable('quiet');
        app.enable('merge javascripts');
        app.enable('merge stylesheets');
        app.disable('assets timestamps');
        //  We don't use express.errorHandler middleware as it can lead to race conditions on res.send
        //  when rendering errors as HTTP and in combination with session saving on memory provider.
        //  TODO: Try to fix the session memory provider as that's most likely its fault.
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
