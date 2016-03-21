module.exports =

    # Couchdb

    getCouchUrl: ->
        @_getUrl 'Couch'
    getCouchSchema: ->
        process.env.COUCH_SCHEMA or 'http'
    getCouchHost: ->
        process.env.COUCH_HOST or 'localhost'
    getCouchPort: ->
        process.env.COUCH_PORT or '5984'


    # Controller

    getControllerUrl: ->
        @_getUrl 'Controller'
    getControllerSchema: ->
        process.env.CONTROLLER_SCHEMA or 'http'
    getControllerHost: ->
        process.env.CONTROLLER_HOST or 'localhost'
    getControllerPort: ->
        process.env.CONTROLLER_PORT or '9002'


    # Proxy

    getProxyUrl: ->
        @_getUrl 'Proxy'
    getProxySchema: ->
        process.env.PROXY_SCHEMA or 'http'
    getProxyHost: ->
        process.env.PROXY_HOST or 'localhost'
    getProxyPort: ->
        process.env.PROXY_PORT or '9104'


    # Data System

    getDataSystemUrl: ->
        @_getUrl 'DataSystem'
    getDataSystemSchema: ->
        process.env.DATASYSTEM_SCHEMA or 'http'
    getDataSystemHost: ->
        process.env.DATASYSTEM_HOST or 'localhost'
    getDataSystemPort: ->
        process.env.DATASYSTEM_PORT or '9101'


    # Home

    getHomeUrl: ->
        @_getUrl 'Home'
    getHomeSchema: ->
        process.env.HOME_SCHEMA or 'http'
    getHomeHost: ->
        process.env.HOME_HOST or 'localhost'
    getHomePort: ->
        process.env.HOME_PORT or process.env.DEFAULT_REDIRECT_PORT or '9103'


    # Files

    getFilesUrl: ->
        @_getUrl 'Files'
    getFilesSchema: ->
        process.env.FILES_SCHEMA or 'http'
    getFilesHost: ->
        process.env.FILES_HOST or 'localhost'
    getFilesPort: ->
        process.env.FILES_PORT or '9121'


    # Helper

    _getUrl: (name) ->
        schema = "get#{name}Schema"
        port = "get#{name}Port"
        host = "get#{name}Host"

        "#{@[schema]()}://#{@[host]()}:#{@[port]()}"
