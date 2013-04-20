# SauceBot Module: JTV API

Sauce = require '../sauce'
db    = require '../saucedb'
io    = require '../ioutil'

request = require 'request'
util    = require 'util'

# Static imports
{ConfigDTO, HashDTO} = require '../dto'
{Cache, WebCache   } = require '../cache'
{Module            } = require '../module'
{TokenJar          } = require '../../common/oauth'


# Module description
exports.name        = 'JTV'
exports.version     = '1.1'
exports.description = 'JustinTV/TwitchTV API'

exports.strings = {
    'show-game'   : '@1@ is playing @2@'
    'show-viewers': 'There are currently @1@ viewers!'
    'show-views'  : 'This channel has been viewed @1@ times!'
    'show-title'  : '@1@'
}

# Set up oauth jar to access the twitch API
oauth = new TokenJar Sauce.API.Twitch, Sauce.API.TwitchToken

# Set up caches for ttv(twitch.tv) and jtv(justin.tv) API calls
ttvcache = new Cache (key, cb) ->
    oauth.get "/channels/#{key}", (resp, body) ->
        cb body

jtvcache = new WebCache (key) -> "http://api.justin.tv/api/stream/list.json?channel=#{key}"

strip = (msg) -> msg.replace /[^a-zA-Z0-9_]/g, ''

class JTV extends Module
    load: ->
        @registerHandlers()
        
        
    registerHandlers: ->
        @regCmd "game",    Sauce.Level.Mod, @cmdGame
        @regCmd "viewers", Sauce.Level.Mod, @cmdViewers
        @regCmd "views",   Sauce.Level.Mod, @cmdViews
        @regCmd "title",   Sauce.Level.Mod, @cmdTitle
        @regCmd "sbfollow", Sauce.Level.Owner, @cmdFollow
        
        @regVar 'jtv', @varJTV


    # !game - Print current game.
    cmdGame: (user, args, bot) =>
        @getGame @channel.name, (game) =>
            bot.say '[Game] ' + @str('show-game', @channel.name, game)
            

    # !viewers - Print number of viewers.
    cmdViewers: (user, args, bot) =>
        @getViewers @channel.name, (viewers) =>
            bot.say "[Viewers] " + @str('show-viewers', viewers)
            

    # !views - Print number of views.
    cmdViews: (user, args, bot) =>
        @getViews @channel.name, (views) =>
            bot.say "[Views] " + @str('show-views', views)
         

    # !title - Print current title.
    cmdTitle: (user, args, bot) =>
        @getTitle @channel.name, (title) =>
            bot.say "[Title] " + @str('show-title', title)


    # !sbfollow <username> - Follows the channel (globals only)
    cmdFollow: (user, args, bot) =>
        return unless user.name.toLowerCase() is 'ravn'
        name = args[0].trim()
        name = name.replace(/[^a-zA-Z0-9_]+/g, '')
        unless name?
            return bot.say "Usage: !sbfollow <channel>"

        io.debug "Following #{name}"
        oauth.put "/users/saucebot/follows/channels/#{name}", (resp, body) ->
            bot.say "Followed #{name}"
           

    # $(jtv game|viewers|views|title [, <channel>])
    varJTV: (user, args, cb) =>
        usage = '[jtv game|viewers|views|title [, <channel>]]'
        unless args[0]?
            cb usage
        else
            chan = if args[1]? then strip(args[1]) else @channel.name
            switch args[0]
                when 'game'    then @getGame    chan, cb
                when 'viewers' then @getViewers chan, cb
                when 'views'   then @getViews   chan, cb
                when 'title'   then @getTitle   chan, cb
                else cb usage
         
         
    getGame: (chan, cb) ->
        @getTTVData chan, (data) ->
            cb (data["game"] ? "N/A")
            
            
    getViewers: (chan, cb) ->
        @getJTVData chan, (data) ->
            cb (data["channel_count"] ? "N/A")
            
            
    getViews: (chan, cb) ->
        @getJTVData chan, (data) ->
            cb (data["channel_view_count"] ? "N/A")
            
            
    getTitle: (chan, cb) ->
        @getTTVData chan, (data) ->
            cb (data["status"] ? "N/A")
            
            
    getTTVData: (chan, cb) ->
        ttvcache.get chan.toLowerCase(), (data) ->
            cb data ? {}


    getJTVData: (chan, cb) ->
        jtvcache.get chan.toLowerCase(), (data) ->
            data = data?[0]
            data = {} unless data?["channel"]?["login"]?.toLowerCase() is chan
            cb data


exports.New = (channel) -> new JTV channel
