
//  Defines routing for the application. We don't use generic routing on purpose
//  to avoid exposing all the controller functions.

/* jshint -W071 */
exports.routes = function (map) {

//  Root

    map.root('home#index');
    map.get('app', 'home#index');
    map.get('app/*', 'home#index');
    map.put('app', 'home#index');
    map.put('app/*', 'home#index');
    map.post('app', 'home#index');
    map.post('app/*', 'home#index');

//  API v1 routes independet of userId

    map.get('1/api/error/404', 'error#error404');
    map.get('1/api/error/:code', 'error#errorCode');

    map.get('1/api/auth/session', 'auth#session');
    map.put('1/api/auth/signout', 'auth#signout');

//  API v1 routes dependent to userId

    map.post('1/api/user/:userId', 'user#post');

    map.get('1/api/user/:userId/provider/data', 'dataProvider#get');
    map.put('1/api/user/:userId/provider/data', 'dataProvider#put');
    map.get('1/api/user/:userId/provider/data/available', 'dataProvider#getAvailableProviders');
    map.get('1/api/user/:userId/provider/data/:providerDbId', 'dataProvider#getProvider');
    map.get('1/api/user/:userId/provider/data/:providerDbId/data', 'dataProvider#getProviderData');

    map.get('1/api/user/:userId/provider/backup', 'backupProvider#get');
    map.put('1/api/user/:userId/provider/backup', 'backupProvider#put');
    map.get('1/api/user/:userId/provider/backup/available', 'backupProvider#getAvailableProviders');
    map.get('1/api/user/:userId/provider/backup/:providerDbId', 'backupProvider#getProvider');
    map.get('1/api/user/:userId/provider/backup/:providerDbId/data', 'backupProvider#getProviderData');

    map.get('1/api/user/:userId/calendar', 'user#calendar');
    map.get('1/api/user/:userId/calendar/:month/:day', 'user#day');

    map.get('1/api/user/:userId/search/text', 'search#text');

    map.get('1/api/user/:userId/stats', 'stats#general');

//  Special development API.

    map.get('1/api/user/:userId/__developmentOnlyCollectUserDataOnDemand', 'user#__developmentOnlyCollectUserDataOnDemand');
    map.get('1/api/user/:userId/__developmentOnlySendDailyEmailsOnDemand', 'user#__developmentOnlySendDailyEmailsOnDemand');
    map.get('1/api/user/:userId/__developmentOnlyBackupUserDataOnDemand', 'user#__developmentOnlyBackupUserDataOnDemand');
    map.get('1/web/auth/__developmentOnlyRedirectedSignIn', 'auth#__developmentOnlyRedirectedSignIn');

//  Authorizations are *web pages* (not API routes) which are invoked by clients.

    map.get('1/web/auth/signin', 'auth#signin');
    map.get('1/web/auth/signedin', 'auth#signedin');

//  These are requests to add user data provider.

    map.get('1/web/user/auth/data/twitter/add', 'twitterAuth#add');
    map.get('1/web/user/auth/data/twitter/callback', 'twitterAuth#callback');
    map.get('1/web/user/auth/data/dropbox/add', 'dropboxAuth#add');
    map.get('1/web/user/auth/data/dropbox/callback', 'dropboxAuth#callback');
    map.get('1/web/user/auth/data/evernote/add', 'evernoteAuth#add');
    map.get('1/web/user/auth/data/evernote/callback', 'evernoteAuth#callback');
    map.get('1/web/user/auth/data/facebook/add', 'facebookAuth#add');
    map.get('1/web/user/auth/data/facebook/callback', 'facebookAuth#callback');
    map.get('1/web/user/auth/data/google-plus/add', 'googlePlusAuth#add');
    map.get('1/web/user/auth/data/google-plus/callback', 'googlePlusAuth#callback');
    map.get('1/web/user/auth/data/slack/add', 'slackAuth#add');
    map.get('1/web/user/auth/data/slack/callback', 'slackAuth#callback');
    map.get('1/web/user/auth/data/foursquare/add', 'foursquareAuth#add');
    map.get('1/web/user/auth/data/foursquare/callback', 'foursquareAuth#callback');

//  Newsletter routes.

    map.post('1/web/newsletter/subscribe', 'newsletter#subscribe');
    map.get('1/web/newsletter/:id/confirmed', 'newsletter#confirmed');

//  These are requests to add user backup provider.

    map.get('1/web/user/auth/backup/dropbox/add', 'dropboxBackupAuth#add');
    map.get('1/web/user/auth/backup/dropbox/callback', 'dropboxBackupAuth#callback');

//  Catch-alls

    map.get('1/api/*', 'error#apiError404');
    map.get('*', 'error#webError404');

};
