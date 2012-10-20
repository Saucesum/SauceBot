# Steam API module

request = require 'request'
io      = require './ioutil'
Sauce   = require './sauce'

API_ROOT = "http://api.steampowered.com"

games = {}

class Steam
    
    constructor: (@channel) ->
        @loaded = false
        
    
    load: ->
        @channel.register 'steam news', Sauce.Level.User, news
        @channel.register 'steam user', Sauce.Level.User, user
    
    
    news: (user, args, bot) ->
        game = args[0].toLowerCase()
        gameID = id for id, name of games if name.toLowerCase() = game
        
        get 'ISteamNews', 'GetNewsForApp', 2, { appid : gameID }, (data) ->
            # TODO Figure out how to display news
    
    
    user: (user, args, bot) ->
        username = args[0].toLowerCase()
        # TODO Figure out how to look up a user profile (might need API key)


# Fetches a resource from the Steam API.
#
# * access: an object describing how to access the resource; valid values are:
#           * api: the Steam API to use
#           * method: the Steam method within the API to call
#           * version: the version of the Steam method to use
#           * key (optional): a Steam API key to use
# * parameters: parameters to pass with the method call
# * callback: a callback that takes the API response as an argument
get: (access, parameters, callback) ->
    parameters.key = access.key if access.key?
    
    options = {
        method : 'GET'
        url    : "#{API_ROOT}/#{access.api}/#{access.method}/v#{('000' + access.version).slice(-4)}"
        qs     : parameters
        json   : true
    }
    
    request options, (error, response, body) =>
        return io.err error if error?
        return io.err "no body in response #{response.statusCode}" unless body?
        callback body
            

# Load the list of games once
get 'ISteamApps', 'GetAppList', 2, {}, (data) ->
    return io.err "no games found from GetAppList" unless data?.applist?.apps?
    
    games[id] = name for id, name of data.applist.apps
