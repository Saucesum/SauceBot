# Cache utility

request = require 'request'

# Default timeout for when no timeout is specified
DEFAULT_TIMEOUT = 5 * 60 * 1000

# Utility class to store cached data
class Cache

    # Constructs a new cache with an updater and timeout.
    #
    # * updater: The callback returning updated values.
    #            It is called with a key representing the
    #            requested element and a callback.
    # * timeout: The time in milliseconds to store cached values.
    #            Defaults to DEFAULT_TIMEOUT.
    constructor: (@updater, @timeout) ->
        @timeout ?= DEFAULT_TIMEOUT

        # Cache store { key: { time, data } }
        @cache = {}


    # Returns the value represented by the specified key.
    # The value returned may be cached.
    #
    # * key: The key to use for the updater.
    # * cb : The method to call once the data is fetched.
    get: (key, cb) ->
        if @isCached key
            console.log "Cached!"
            cb @getCached key
        else
            console.log "Not cached!"
            @fetch key, cb


    fetch: (key, cb) ->
        # Get data from the cache updater
        @updater key, (data) =>
            now = Date.now()
    
            # Store data in cache
            @cache[key] =
                time: now
                data: data

            cb data

        
    isCached: (key) ->
        if (cached = @cache[key])?
            return cached.time + @timeout > Date.now()
        else
            return false


    getCached: (key) ->
        return @cache[key]?.data


    # Removes all cached data from the cache store.
    # Subsequent calls to Cache.get(key, cb) with different
    # keys will guarantee updated results.
    clear: ->
        @cache = {}


# Cache implementation for web data
class WebCache extends Cache

    # Constructs a new web cache with an url generator and timeout.
    #
    # * urlGenerator: A generator called to get an URL based on keys.
    #                 Example:
    #                   urlGenerator("CilantroGamer") =>
    #                   "https://api.twitch.tv/kraken/channels/CilantroGamer"
    # * timeout: Optional timeout in milliseconds.
    constructor: (@urlGenerator, @timeout) ->
        super(@webFetcher, @timeout)


    webFetcher: (key, cb) ->
        url = @urlGenerator key
        request {url: url, timeout: 2000}, (err, resp, json) =>
            try
                data = JSON.parse json
                cb data
            catch err
                # Ignore
                cb()

exports.Cache    = Cache
exports.WebCache = WebCache
