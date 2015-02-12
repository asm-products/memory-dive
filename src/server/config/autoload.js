
module.exports = function (compound) {

    var defaultModules = [
        'jugglingdb',
        'co-assets-compiler',
        'compound-passport',
        '../app/collectors/dropboxCollector',
        '../app/collectors/evernoteCollector',
        '../app/collectors/facebookCollector',
        '../app/collectors/foursquareCollector',
        '../app/collectors/readabilityCollector',
        '../app/collectors/slackCollector',
        '../app/collectors/twitterCollector',
        '../app/common/api1UrlCreator',
        '../app/common/bulkDataUploader',
        '../app/common/constants',
        '../app/common/dbIdCreator',
        '../app/common/emailSender',
        '../app/common/hellRaiser',
        '../app/common/itemRenderer',
        '../app/common/login',
        '../app/common/mailer',
        '../app/common/objectFactory',
        '../app/common/scheduler',
        '../app/common/timeLord',
        '../app/common/tracker',
        '../app/common/userDataGovernor',
        '../app/common/userDataStatistician',
        '../app/persistors/dropboxPersistor',
        '../app/workers/backupAdminWorker',
        '../app/workers/collectorWorker',
        '../app/workers/dropboxWorker',
        '../app/workers/evernoteWorker',
        '../app/workers/facebookWorker',
        '../app/workers/foursquareWorker',
        '../app/workers/genericWorker',
        '../app/workers/slackWorker',
        '../app/workers/twitterWorker'
    ], developmentModules = [];

    if ('development' === compound.app.get('env')) {
        developmentModules = [
            'seedjs',
            'co-generators'
        ];
    }

    if (typeof window === 'undefined') {
        return defaultModules.concat(developmentModules).map(require);
    } else {
        return [];
    }

};
