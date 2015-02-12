
'use strict';

//  Our BaseController keeps the stuff common for all our controllers:
//      - It sets up __missingAction action for all controllers allowing us to send missing actions to 404.
//      - It sets up the default this.title required by application_layout.ejs (this allows views missing .title not to crash with bizzare messages)

module.exports = BaseController;

function BaseController(init) {
    //  We use class name for functions to avoid clashes with super or inheriting classes.
    init.before(BaseController.prototype.before);
}

BaseController.prototype.__missingAction = function(c) {
    //  We redirect all missing actions to our 404 page.
    c.redirectError(404);
};

BaseController.prototype.before = function(c) {
    //  Setup the default title to controller name and action.
    //  TODO: Redesign application_layout to be "smarter" about missing title or another way to choose default title.
    //this.title = c.controllerName + ' - ' + c.actionName;

    c.next();
};
