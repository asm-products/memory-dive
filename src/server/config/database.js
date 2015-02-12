module.exports = {
   'development': {
      'driver':   'nano',
      'url':      process.env.MEMORY_DIVE_COUCHDB_SERVER_URL
   },
   'test': {
      'driver':   'nano',
      'url':      process.env.MEMORY_DIVE_COUCHDB_SERVER_URL__TEST__ || 'http://localhost:5984/panta-rhei-tests'
   },
   'integration': {
      'driver':   'nano',
      'url':      process.env.MEMORY_DIVE_COUCHDB_SERVER_URL
   },
   'production': {
      'driver':   'nano',
      'url':      process.env.MEMORY_DIVE_COUCHDB_SERVER_URL
   }
};
