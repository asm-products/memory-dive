
'use strict';

//  Our SignedInController keeps the stuff common for all our controllers that require the user to be signed in:
//      - It checks that the user is signed in and forwards unsigned users to signing in.
//      - It checks that the signed in user corresponds to the URL user ID path.

module.exports = SignedInBaseController;

var BaseController = require('./base');
var jsend = require('express-jsend');

function SignedInBaseController(init) {
    BaseController.call(this, init);

    //  We use class name for functions to avoid clashes with super or inheriting classes.
    init.before(SignedInBaseController.prototype.before);
}

require('util').inherits(SignedInBaseController, BaseController);

SignedInBaseController.prototype.before = function(c) {

    console.log('count#api-call=1');

//  Before any action check that the user is signed in.

    if(!c.req.user) {

//  Return 401 - Unauthorized
        console.log('count#api-error-401=1');
        return c.res.status(401).jfail('Please sign-in.');

    }

//  Check that the userId has been specified.

    var id = c.params.userId || c.params.id;
    if(!id) {

//  Return 400 - Bad request
        console.log('count#api-error-400=1');
        return c.res.status(400).jfail('Invalid request made.');

    }

//  Check that the user requesting the resource is the owner of resource.

    if(c.req.user.id !== id) {

//  Return 403 - Forbidden
        console.log('count#api-error-403=1');
        return c.res.status(403).jfail('You don\'t own this resource');

    }

//  We set the user for the controller and all inheriting controllers.

    this.user = c.req.user;

    c.next();

};
