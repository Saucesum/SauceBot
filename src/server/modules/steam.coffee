# Steam API module

request = require 'request'
io      = require './ioutil'
Sauce   = require './sauce'

# Module description
exports.name        = 'Steam'
exports.version     = '1.0'
exports.description = 'Steam API'

API_ROOT = 'http://api.steampowered.com'
NEWS_COUNT = 1

games = {}
gamesArray = []

class Steam
    
    constructor: (@channel) ->
        @loaded = false
        
    
    load: ->
        return if @loaded
        
        # Load the list of all games
        get {
            api     : 'ISteamApps'
            method  : 'GetAppList'
            version : 2
        }, {}, (data) ->
            return io.err "no games found from GetAppList" unless data.applist?.apps?
            
            games[entry.id] = entry.name for entry in data.applist.apps
            gamesArray.push { id: id, name: name } for id, name of games
            
            @channel.register 'steam news', Sauce.Level.User, news
            @channel.register 'steam user', Sauce.Level.User, user
            
            @loaded = true
    
    
    unload: ->
        return unless @loaded
        
        @channel.register 'steam news', Sauce.Level.User, news
        @channel.register 'steam user', Sauce.Level.User, user
        
        @loaded = false
    
    
    news: (user, args, bot) ->
        game = args[0..].join(' ').toLowerCase()
        
        matches = gamesArray
        .filter((e) -> e.name.toLowerCase().indexOf(game) isnt -1)
        .sort((a, b) -> a.name.length - b.name.length)
        
        return bot.say "Game \"#{game}\" not found" unless matches
        
        get {
            api     : 'ISteamNews'
            method  : 'GetNewsForApp'
            version : 2
        }, {
            appid : matches[0].id
        }, (data) ->
            return bot.say "No news found for #{game}" unless data.appnews?.newsitems?
            news = data.appnews.newsitems[0..NEWS_COUNT - 1]
            bot.say "News for #{matches[0].name} from #{formatDate new Date item.date}: #{item.title}" for item in news
    
    
    user: (user, args, bot) ->
        username = args[0].toLowerCase()
        # TODO Figure out how to look up a user profile (might need API key)


sanitize = (string) ->
    string.replace /<[^>]+>|\n|\r/, ''


formatDate = (date) ->
    "#{date.getMonth()/date.getDate()/date.getFullYear()}"


# Fetches a resource from the Steam API.
#
# * access: an object describing how to access the resource; valid values are:
#           * api: the Steam API to use
#           * method: the Steam method within the API to call
#           * version: the version of the Steam method to use
#           * key (optional): a Steam API key to use
# * parameters: parameters to pass with the method call
# * callback: a callback that takes the API response as an argument
get = (access, parameters, callback) ->
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

exports.New = (channel) -> new Steam channel 
