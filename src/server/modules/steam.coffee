# Steam API module

request = require 'request'
io      = require './ioutil'
Sauce   = require './sauce'

# Module description
exports.name        = 'Steam'
exports.version     = '1.0'
exports.description = 'Steam API'

prefix = '[Steam]: '

exports.strings = {
    'date-format' : '@3@-@2@-@1@'
    'no-game'     : 'Game "@1@" not found'
    'no-news'     : 'No news found for @1@'
    'news-item'   : 'News for @1@ from @2@: @3@'
}

API_ROOT = 'http://api.steampowered.com'
NEWS_COUNT = 1

games = []

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
            
            games = data.applist.apps
            
            @channel.register 'steam news', Sauce.Level.User, news
            @channel.register 'steam user', Sauce.Level.User, user
            
            @loaded = true
    
    
    unload: ->
        return unless @loaded
        
        myTriggers = @channel.listTriggers { module: this }
        @channel.unregister myTriggers...
        
        @loaded = false
    
    
    news: (user, args, bot) ->
        game = args[0..].join(' ').toLowerCase()
        
        matches = games
        .filter((e) -> e.name.toLowerCase().indexOf(game) isnt -1)
        .sort((a, b) -> a.name.length - b.name.length)
        
        return @say bot, @str('no-game', game) unless matches
        
        get {
            api     : 'ISteamNews'
            method  : 'GetNewsForApp'
            version : 2
        }, {
            appid : matches[0].appid
        }, (data) ->
            return @say bot, @str('no-news', game) unless data.appnews?.newsitems?
            news = data.appnews.newsitems[0..NEWS_COUNT - 1]
            @say bot, @str('news-item', matches[0].name, formatDate new Date item.date, item.title) for item in news
    
    
    user: (user, args, bot) ->
        username = args[0].toLowerCase()
        # TODO Figure out how to look up a user profile (might need API key)
    
    
    say: (bot, message) ->
        bot.say prefix + message
    
    
    formatDate = (date) ->
        @str('date-format', date.getDay(), date.getMonth(), date.getFullYear())


# Very basic removal of HTML tags from a string.
#
# * string: the string to sanitize
sanitize = (string) ->
    string.replace /<[^>]+>|\n|\r/g, ''




# Fetches a resource from the Steam API.
#
# * access: an object describing how to access the resource; valid values are:
#      * api: the Steam API to use
#      * method: the Steam method within the API to call
#      * version: the version of the Steam method to use
#      * key (optional): a Steam API key to use
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
