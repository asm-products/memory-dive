
# User backup provider model

    debug   = (require 'debug') 'memdive::models::UserBackupProvider'
    _       = require 'lodash'

## Exported methods

    module.exports = (compound, UserBackupProvider) ->

`UserBackupProvider` model inherits `UserProviderModelBase` because it providers services over the same schema that `UserDataProvider` model has. Both of these models inherit `UserProviderModelBase`.

        UserProviderModelBase = require '../common/UserProviderModelBase'

        inheritingModel =
            object:             UserBackupProvider
            name:               'UserBackupProvider'
            dbIdCreatorName:    'createUserBackupProviderObjectId'

        UserProviderModelBase(compound, inheritingModel)
