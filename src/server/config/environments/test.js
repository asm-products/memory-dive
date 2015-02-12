var express = require('express');

module.exports = function (compound) {
    var app = compound.app;

    app.configure('test', function () {
        console.log('Configuring app for test');

        app.enable('quiet');
        app.enable('view cache');
        app.enable('model cache');
        app.enable('eval cache');
        //  We don't use express.errorHandler middleware as it can lead to race conditions on res.send
        //  when rendering errors as HTTP and in combination with session saving on memory provider.
        //  TODO: Try to fix the session memory provider as that's most likely its fault.
        //app.use(express.errorHandler({ dumpExceptions: true, showStack: true }));
    });
};
