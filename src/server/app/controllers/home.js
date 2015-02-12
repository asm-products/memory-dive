
'use strict';

module.exports = HomeController;

var BaseController = require('./base');

function HomeController(init) {
    BaseController.call(this, init);
}

require('util').inherits(HomeController, BaseController);

HomeController.prototype.index = function(c) {

    if(!c.req.user) {
        return c.res.redirect('/landing?r=' + encodeURIComponent(c.compound.common.config.BASE_URL + c.req.originalUrl));
    }

    this.title = 'Home';
    c.render({user: c.req.user});

};
