# SauceBot Server Configurations

conf = require '../common/config'

# Default values for the configurations.
exports.DEFAULTS = {
    # Server version
    Version: '3.3'

    DBDump: __dirname + '/../../db/my.sql'
    
    # Moderator levels
    Level:
        User : 0
        Mod  : 1
        Admin: 2
        Owner: 3

    # Twitch SPECIALUSER roles
    Role:
        Admin: 'admin'
        Staff: 'staff'
        Subscriber: 'subscriber'
        Turbo: 'turbo'

    # Action types
    Action:
        JOIN  : 0
        LEAVE : 1
        REJOIN: 2

        SAY    : 3
        TIMEOUT: 4
        UNBAN  : 5

        COMMERCIAL: 6

    
    # -- Default values for config file data --

    # Database settings
    MySQL:
        Username: 'root'
        Password: ''
        Database: 'sauce'

    # Log settings
    Logging:
        Root: __dirname + '/../../logs/'
    
    # Graphing (statsd/graphite) config
    Graphing:
        Host: 'localhost'
        Port: 8125
        Name: 'saucebot.'

    # Net settings
    Server:
        Name: 'SauceBot'
        Port: 28333

    # Api keys
    API:
        Twitch: null
        TwitchToken: null
        LastFM: null
        Steam : null
}

# Flag to specify whether data has been loaded
loaded = false

# Loads default values
init = ->
    exports.load exports.DEFAULTS
    loaded = false

exports.isLoaded = -> loaded

# Loads the configurations.
exports.load = (data) ->
    for key, value of data

        if typeof value is 'object'
            for vKey, vValue of value
                exports[key] ?= {}
                exports[key][vKey] = vValue

        else
            exports[key] = value

    loaded = true


# Loads the configurations from a JSON file.
exports.loadFile = (dir, file) ->
    data = conf.load dir, file
    exports.load data


init()
