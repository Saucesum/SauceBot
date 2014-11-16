# SauceBot Module: Twitch API

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
exports.name        = 'TwitchAPI'
exports.version     = '1.1'
exports.description = 'TwitchTV API'

exports.strings = {
    'show-game'   : '@1@ is playing @2@'
    'show-viewers': 'There are currently @1@ viewers!'
    'show-views'  : 'This channel has been viewed @1@ times!'
    'show-title'  : '@1@'
}

# Set up oauth jar to access the twitch API
oauth = new TokenJar Sauce.API.Twitch, Sauce.API.TwitchToken

# Set up caches for ttv(twitch.tv) and jtv(justin.tv) API calls
ttvstreamcache = new Cache (key, cb) ->
    oauth.get "/streams/#{key}", (resp, body) ->
        cb body

# Set up caches for ttv(twitch.tv) and jtv(justin.tv) API calls
ttvcache = new Cache (key, cb) ->
    oauth.get "/channels/#{key}", (resp, body) ->
        cb body

jtvcache = new WebCache (key) -> "http://api.justin.tv/api/stream/list.json?channel=#{key}"

strip = (msg) -> msg.replace /[^a-zA-Z0-9_]/g, ''

class TwitchAPI extends Module
    load: ->
        @registerHandlers()
        
        
    registerHandlers: ->
        @regCmd "game",    Sauce.Level.Mod, @cmdGame
        @regCmd "viewers", Sauce.Level.Mod, @cmdViewers
        @regCmd "title",   Sauce.Level.Mod, @cmdTitle
        @regCmd "sbfollow", Sauce.Level.Owner, @cmdFollow
        @regCmd "followme", Sauce.Level.Owner, @cmdFollowMe
        
        @regVar 'jtv', @varJTV


    # !game - Print current game.
    cmdGame: (user, args) =>
        @getGame @channel.name, (game) =>
            @bot.say '[Game] ' + @str('show-game', @channel.name, game)
            

    # !viewers - Print number of viewers.
    cmdViewers: (user, args) =>
        @getViewers @channel.name, (viewers) =>
            @bot.say "[Viewers] " + @str('show-viewers', viewers)
            

    # !title - Print current title.
    cmdTitle: (user, args) =>
        @getTitle @channel.name, (title) =>
            @bot.say "[Title] " + @str('show-title', title)


    # !sbfollow <username> - Follows the channel (globals only)
    cmdFollow: (user, args) =>
        return unless user.global

        name = args[0]
        if name = @followUser(name)
            @bot.say "Followed #{name}"
        else
            @bot.say "Usage: !sbfollow <username>"


    # !followme - Follows channel
    cmdFollowMe: (user, args) =>
        if @followUser(user.name)
            @bot.say "Followed #{user.name}"
        else
            @bot.say "Invalid username. Please contact a SauceBot administrator."


    followUser: (name) ->
        name = name.trim()
        name = name.replace(/[^a-zA-Z0-9_]+/g, '')
        return unless name
        
        io.debug "Following #{name}"
        oauth.put "/users/saucebot/follows/channels/#{name}", (resp, body) ->
            io.debug "Followed #{name}"
        return name
           

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
        @getTTVStreamData chan, (data) ->
            cb ((data["stream"] ? {})["viewers"] ? "N/A")
            
            
    getTitle: (chan, cb) ->
        @getTTVData chan, (data) ->
            cb (data["status"] ? "N/A")
            
            
    getTTVStreamData: (chan, cb) ->
        ttvstreamcache.get chan.toLowerCase(), (data) ->
            cb data ? {}


    getTTVData: (chan, cb) ->
        ttvcache.get chan.toLowerCase(), (data) ->
            cb data ? {}


    getJTVData: (chan, cb) ->
        jtvcache.get chan.toLowerCase(), (data) ->
            data = data?[0]
            data = {} unless data?["channel"]?["login"]?.toLowerCase() is chan
            cb data


exports.New = (channel) -> new TwitchAPI channel
