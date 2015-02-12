
# User data provider model

    debug   = (require 'debug') 'memdive::models::UserDataProvider'
    _       = require 'lodash'

## Exported methods

    module.exports = (compound, UserDataProvider) ->

`UserDataProvider` model inherits `UserProviderModelBase` because it providers services over the same schema that `UserBackupProvider` model has. Both of these models inherit `UserProviderModelBase`.

        UserProviderModelBase = require '../common/UserProviderModelBase'

        inheritingModel =
            object:            UserDataProvider
            name:              'UserDataProvider'
            dbIdCreatorName:   'createUserDataProviderObjectId'

        UserProviderModelBase(compound, inheritingModel)
