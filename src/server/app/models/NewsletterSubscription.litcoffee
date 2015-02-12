
This module is responsible for:
 1. Creating NewsletterSubscription objects from emails.
 2. Persisting NewsletterSubscription objects to database backend.
 3. Loading NewsletterSubscription objects from database backend.

For logging and other tasks we use several external modules.

    debug   = (require 'debug') 'memdive::models::NewsletterSubscription'

NewsletterSubscription has the following public methods:

1. createObject - creates NewsletterSubscription object with the given data

    module.exports = (compound, NewsletterSubscription) ->

        createObject = (data) ->

            timestamp = (new Date()).getTime()

            object = new compound.models.NewsletterSubscription {
                    model:          'NewsletterSubscription'
                    email:          data.email
                    status:         'new'
                    createdOn:      timestamp
                    timestamp:      timestamp
                }

            return object

        NewsletterSubscription.createObject = createObject
