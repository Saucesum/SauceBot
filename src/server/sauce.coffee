# SauceBot Configurations

config = require './config'
io     = require './ioutil'


# Returns a string representing the specified level.
# + Anything over "Owner" will be returned as "Global".
# + Anything under "User" will be returned as "None".
exports.LevelStr = (level) ->
    switch level
        when exports.Level.User  then 'User'
        when exports.Level.Sub   then 'Subscriber'
        when exports.Level.Mod   then 'Moderator'
        when exports.Level.Admin then 'Administrator'
        when exports.Level.Owner then 'Owner'
        else
            if level > exports.Level.Owner then 'Global' else 'None'

# Import exports from the config loader.
exports.reload = ->
    if config.isLoaded()
        exports[k] = v for k, v of config
    else
        io.error "No config file loaded"

