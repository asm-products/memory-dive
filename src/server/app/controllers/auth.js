'use strict';

var debug = require('debug')('memdive::controllers::auth')
  , jsend = require('express-jsend');

module.exports = AuthController;

var BaseController = require('./base');

function AuthController(init) {
    BaseController.call(this, init);

    //  We use class name for functions to avoid clashes with super or inheriting classes.
    init.before(AuthController.prototype.before);
}

require('util').inherits(AuthController, BaseController);

AuthController.prototype.before = function(c) {

    console.log('count#auth-call=1');

    c.next();

};

AuthController.prototype.signin = function(c) {

//  If the redirection hasn't yet been defined the user is
//  signing in manually (vs. being redirect by SignedInBaseController.before)
//  so we want to redirect the browser to signedin on successful signing in
//  and from there to the default user view.

    c.compound.common.login.signIn(c, c.req.session.redirect || '/1/web/auth/signedin');

};

AuthController.prototype.signedin = function(c) {

    c.compound.common.login.signedIn(c);

};

AuthController.prototype.signout = function(c) {

    c.compound.common.tracker.userSignedOut(c.req.user);

    c.req.session.destroy(function(error) {
        if(error) {
            debug('Error while signing out:', error);
        }
    });
    c.req.session = undefined;
    c.req.logout();

//  We must undefine the user as otherwise it (apparently) remains stored somewhere
//  and logout is not *really* a log out (when pressing sing in the signing in is way too fast
//  without any redirections to OAuth site)

    c.req.user = undefined;

    c.res.status(200).jsend();

};

AuthController.prototype.__developmentOnlyRedirectedSignIn = function(c) {

    debug('signing in with redirect', c.req.query.redirect);

    var redirect = c.req.query.redirect;
    if(!redirect) {
        AuthController.prototype.signIn(c);
    } else {
        c.compound.common.login.signIn(c, '/1/web/auth/signedin?redirect=' + encodeURIComponent(redirect));
    }

};

AuthController.prototype.session = function(c) {

    var user = c && c.req && c.req.user;

    if(!user) {
        return c.res.status(403).jsend({});
    }

    c.res.status(200).jsend({
        id:             user.id,
        //  We send the revision of the user's database doc.
        //  This allows us to deny updates if database's state changed
        //  between the retrieval of this info and the update in question.
        rev:            user._rev,
        displayName:    user.displayName,
        username:       user.username,
        email:          user.email,
        picture:        user.picture,
        timezone:       user.timezone,
        createdOn:      user.createdOn
    });

};
