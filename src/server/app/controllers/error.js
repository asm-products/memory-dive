'use strict';

module.exports = ErrorController;

var BaseController = require('./base');
var jsend = require('express-jsend');

function ErrorController(init) {
    BaseController.call(this, init);

    //  We use class name for functions to avoid clashes with super or inheriting classes.
    init.before(ErrorController.prototype.before);
}

require('util').inherits(ErrorController, BaseController);

ErrorController.prototype.before = function(c) {
    this.title = 'Error';
    //  The session user may not exist but if it does then the header will be correctly rendered.
    this.user = c.req.user;
    c.next();
};

ErrorController.prototype.error = function(c) {
    this.code = 'unknown';
    c.res.status(500).jerror({ code: 500, description: 'Sorry, our bad - we are trying to fix it!' });
};

ErrorController.prototype.error404 = function(c) {
    c.res.status(404).jerror({ code: 404, description: 'Sorry, no such page!' });
};

ErrorController.prototype.apiError404 = function(c) {
    c.res.status(404).jerror({ code: 404, description: 'Sorry, no such page!' });
};

ErrorController.prototype.errorCode = function(c) {
    c.res.status(c.params.code).jerror({ code: c.params.code, description: 'TODO: read from description/language matrix' });
};

ErrorController.prototype.webError404 = function(c) {
    c.redirectError(404, 'Page not found', '/app/error');
};
