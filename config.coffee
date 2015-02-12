# brunch config, see http://brunch.io/#documentation for docs.

exports.config =
  ## we won't be using this for now
  # server:
  #   path: 'src/server/server.coffee'
  #   port: 3000
  #   base: '/'
  #   run:  yes

  conventions:
    ## assets: add extensions at the end, separated by |, to copy the files
    ##  below '/src/client/ directly to the _public dir without compilation.
    ##  also, copy entire '/src/client/landing' directory as is
    assets: /^src\/client\/($|.*\.(html|png|jpg|jpeg|gif|ico)$)|^src\/client\/landing|(assets|font-awesome-bower)\/($|.*\.(eot|svg|ttf|woff)$)/i
    ## see https://github.com/brunch/brunch/blob/stable/docs/config.md#conventions
    ignored: /^(client\/styles\/overrides|bower_components\/bootstrap-sass-official\/vendor\/assets\/stylesheets?)/

  modules:
    definition: false
    wrapper: false

  paths:
    ## public, front-end compiled path
    public: '_public'
    ## front-end source files paths
    watched: ['src/client', 'vendor_files']

  files:
    javascripts:
      joinTo:
        ## join all our source js into app.js
        'js/app.js': /^src\/client/
        ## join all 3rd party js into vendor.js
        'js/vendor.js': /^(bower_components|vendor)/
      order:
        ## brunch use path sort ordering. tell it what to include before and after if necessary.
        before: [
          'bower_components/jquery/dist/jquery.js'
          'bower_components/angular/angular.js'
          'bower_components/angular-route/angular-route.js'
          'bower_components/lodash/dist/lodash.compat.js'
          'bower_components/angular-lodash/angular-lodash.js'
          'src/client/javascripts/app.js'
        ]

    stylesheets:
      ## join our and 3rd party css into app.css
      joinTo:
        'css/app.css': /^(src\/client|bower_components)/
      ## brunch use path sort ordering. tell it what to include before and after if necessary.
      order:
        before: [
          'bower_components/angular-loading-bar/src/loading-bar.css'
          'src/client/stylesheets/application.scss'
        ]

    ## just keeping this here in case we'll need it later
    # templates:
    #   joinTo:
    #     'js/dontUseMe' : /^src\/client/ # dirty hack for Jade compiling.
