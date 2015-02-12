
var debug = require('debug')('memdive::initializers::initCoordinator');
var _ = require('lodash');

module.exports = function (compound) {

    console.log('count#started=1');

    var signals = [
        'api1UrlCreatorReady',
        'backupAdminWorkerReady',
        'bulkDataUploaderReady',
        'collectorReady',
        'constantsReady',
        'couchDbReady',
        'dbIdCreatorReady',
        'dropboxCollectorReady',
        'dropboxPersistorReady',
        'dropboxWorkerReady',
        'emailSenderReady',
        'evernoteCollectorReady',
        'evernoteWorkerReady',
        'facebookCollectorReady',
        'facebookWorkerReady',
        'foursquareCollectorReady',
        'foursquareWorkerReady',
        'genericWorkerReady',
        'hellRaiserReady',
        'itemRendererReady',
        'loginReady',
        'mailerReady',
        'objectFactoryReady',
        'readabilityCollectorReady',
        'ready',
        'schedulerReady',
        'slackCollectorReady',
        'slackWorkerReady',
        'timeLordReady',
        'trackerReady',
        'twitterCollectorReady',
        'twitterWorkerReady',
        'userDataGovernorReady',
        'userDataStatisticianReady'
    ];

    var pendingSignals = {};

    return _.each(signals, function(signal) {

        pendingSignals[signal] = signal;

        compound.on(signal, function() {
            debug(signal, 'received');
            delete pendingSignals[signal];
            emitReadyIfAllSignaled();
        });

    });

    function emitReadyIfAllSignaled() {

        if(_(pendingSignals).keys().isEmpty()) {

            setTimeout(function() {
                debug('MemoryDive ready');
                compound.memoryDiveReady = true;
                compound.emit('memoryDiveReady');
            }, 0);

        } else {

            debug('Still waiting on', _.last(_.keys(pendingSignals)), 'and', _.keys(pendingSignals).length - 1, 'more.');

        }

    }

};
