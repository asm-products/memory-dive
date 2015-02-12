
# Copy this file into env.sh and fill out all the environment variables.
# Variables required by the service itself are obligatory whereas
# variables required by tests are not. Tests are setup to be skipped
# unless all the necessary variables are available (evaluated on each
# test suite separately)

#####################################################################
#                                                                   #
#                             REQUIRED                              #
#                                                                   #
#####################################################################

# Home
export MEMORY_DIVE_BASE_URL=https://<your service url> # e.g. for local tests https://my-ngrok-subdomain.ngrok.com

# Db connections
export MEMORY_DIVE_COUCHDB_SERVER_URL=https://<your cloudant>/memory-dive
export MEMORY_DIVE_COUCHDB_SERVER_URL__TEST__=https://<your cloudant>/memory-dive-tests
export MEMORY_DIVE_COUCHDB_SESSIONS_STORE_URL=https://<your cloudant>/memory-dive-sessions

# Secrets
export MEMORY_DIVE_SESSION_SECRET=<...>
export MEMORY_DIVE_COOKIE_SECRET=<...>

# Other config
export MEMORY_DIVE_AUTH_CALLBACK_REDIRECT_TO_LOCALHOST=<...>

# Facebook
export MEMORY_DIVE_FACEBOOK_APP_ID=<...>
export MEMORY_DIVE_FACEBOOK_APP_SECRET=<...>

# Twitter
export MEMORY_DIVE_TWITTER_CONSUMER_KEY=<...>
export MEMORY_DIVE_TWITTER_CONSUMER_SECRET=<...>

# Iron.IO
export MEMORY_DIVE_IRON_IO_TOKEN=<...>
export MEMORY_DIVE_IRON_IO_PROJECT_ID=<...>

# Dropbox data source
export MEMORY_DIVE_DROPBOX_APP_KEY=<...>
export MEMORY_DIVE_DROPBOX_APP_SECRET=<...>

# Dropbox data sink (backups)
export MEMORY_DIVE_DROPBOX_BACKUP_APP_KEY=<...>
export MEMORY_DIVE_DROPBOX_BACKUP_APP_SECRET=<...>

# Mandrill
export MEMORY_DIVE_MANDRILL_API_KEY=<...>

# Localytics
export MEMORY_DIVE_LOCALYTICS_APP_CODE=<...>

# Evernote
export MEMORY_DIVE_EVERNOTE_CONSUMER_KEY=<...>
export MEMORY_DIVE_EVERNOTE_CONSUMER_SECRET=<...>
export MEMORY_DIVE_EVERNOTE_SANDBOX=<...>

# Google+
export MEMORY_DIVE_GOOGLE_PLUS_CLIENT_ID=<...>
export MEMORY_DIVE_GOOGLE_PLUS_CLIENT_SECRET=<...>

# Slack
export MEMORY_DIVE_SLACK_CLIENT_ID=<...>
export MEMORY_DIVE_SLACK_CLIENT_SECRET=<...>

# Foursquare
export MEMORY_DIVE_FOURSQUARE_CLIENT_ID=<...>
export MEMORY_DIVE_FOURSQUARE_CLIENT_SECRET=<...>

# Mailer
export MEMORY_DIVE_MAILER_TRANSPORT=<...>
export MEMORY_DIVE_MAILER_DEFAULT_FROM=<...>
export MEMORY_DIVE_MAILER_SMTP_ADDRESS=<...>
export MEMORY_DIVE_MAILER_SMTP_PORT=<...>
export MEMORY_DIVE_MAILER_SMTP_DOMAIN=<...>
export MEMORY_DIVE_MAILER_SMTP_USER=<...>
export MEMORY_DIVE_MAILER_SMTP_PASS=<...>

# Segment.IO
export MEMORY_DIVE_SEGMENT_IO_WRITE_KEY=<...>

#####################################################################
#                                                                   #
#                             OPTIONAL                              #
#                                                                   #
#####################################################################

# Facebook test data
export MEMORY_DIVE_TEST_FACEBOOK_USER_ID=<...>
export MEMORY_DIVE_TEST_FACEBOOK_USER_NAME=<...>
export MEMORY_DIVE_TEST_FACEBOOK_TOKEN=<...>
export MEMORY_DIVE_TEST_FACEBOOK_MIN_EXPECTED_UPLOADED_PHOTOS=<...>
export MEMORY_DIVE_TEST_FACEBOOK_MIN_EXPECTED_TAGGED_PHOTOS=<...>
export MEMORY_DIVE_TEST_FACEBOOK_MIN_EXPECTED_UPLOADED_VIDEOS=<...>
export MEMORY_DIVE_TEST_FACEBOOK_MIN_EXPECTED_TAGGED_VIDEOS=<...>
export MEMORY_DIVE_TEST_FACEBOOK_MIN_EXPECTED_LIKES=<...>
export MEMORY_DIVE_TEST_FACEBOOK_MIN_EXPECTED_POSTS=<...>
export MEMORY_DIVE_TEST_FACEBOOK_MIN_EXPECTED_NOTES=<...>
export MEMORY_DIVE_TEST_FACEBOOK_MIN_EXPECTED_ALL_OBJECTS=<...>
export MEMORY_DIVE_TEST_FACEBOOK_COLLECT_PICTURE_URL=<...>

# Twitter test data
export MEMORY_DIVE_TEST_TWITTER_USER_ID=<...>
export MEMORY_DIVE_TEST_TWITTER_TOKEN=<...>
export MEMORY_DIVE_TEST_TWITTER_TOKEN_SECRET=<...>
export MEMORY_DIVE_TEST_TWITTER_MIN_EXPECTED_TWEETS=<...>

# Dropbox test data
export MEMORY_DIVE_TEST_DROPBOX_TOKEN=<...>
export MEMORY_DIVE_TEST_DROPBOX_MIN_EXPECTED_USER_PHOTOS_AND_VIDEOS=<...>
export MEMORY_DIVE_TEST_DROPBOX_MIN_EXPECTED_MIME_TYPES=<...>

# Evernote test data
export MEMORY_DIVE_TEST_EVERNOTE_TOKEN=<...>
export MEMORY_DIVE_TEST_EVERNOTE_USER_ID=<...>
export MEMORY_DIVE_TEST_EVERNOTE_USERNAME=<...>
export MEMORY_DIVE_TEST_EVERNOTE_MIN_EXPECTED_NOTES=<...>

# Slack test data
export MEMORY_DIVE_TEST_SLACK_TOKEN=<...>
export MEMORY_DIVE_TEST_SLACK_TEAM_ID=<...>
export MEMORY_DIVE_TEST_SLACK_USER_ID=<...>
export MEMORY_DIVE_TEST_SLACK_MIN_EXPECTED_MESSAGES=<...>

# Foursquare test data
export MEMORY_DIVE_TEST_FOURSQUARE_TOKEN=<...>
export MEMORY_DIVE_TEST_FOURSQUARE_MIN_EXPECTED_CHECK_INS=<...>
