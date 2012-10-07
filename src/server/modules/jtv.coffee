# SauceBot Module: JTV API

Sauce = require '../sauce'
db    = require '../saucedb'
io    = require '../ioutil'

request = require 'request'
util    = require 'util'

{ConfigDTO, HashDTO} = require '../dto'
{Cache, WebCache   } = require '../cache'


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

cache = new WebCache (key) -> "https://api.twitch.tv/kraken/channels/#{key}"

strip = (msg) -> msg.replace /[^a-zA-Z0-9_]/g, ''

class JTV
    constructor: (@channel) ->
        
        @loaded = false
                
    load: ->
        io.module "[JTV] Loading for #{@channel.id}: #{@channel.name}"

        @registerHandlers() unless @loaded
        @loaded = true

        
    unload: ->
        return unless @loaded
        @loaded = false
        
        io.module "[JTV] Unloading from #{@channel.id}: #{@channel.name}"
        myTriggers = @channel.listTriggers { module:this }
        @channel.unregister myTriggers...
        @channel.vars.unregister 'jtv'

        
    registerHandlers: ->
        @channel.register this, "game", Sauce.Level.Mod,
            (user,args,bot) =>
                @cmdGame user, args, bot

        @channel.register this, "viewers", Sauce.Level.Mod,
            (user,args,bot) =>
                @cmdViewers user, args, bot
        
        @channel.register this, "views", Sauce.Level.Mod,
            (user,args,bot) =>
                @cmdViews user, args, bot
        
        @channel.register this, "title", Sauce.Level.Mod,
            (user,args,bot) =>
                @cmdTitle user, args, bot
        
        @channel.vars.register 'jtv', (user, args, cb) =>
            usage = '$(jtv (game|viewers|views|title))'
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

        
    cmdGame: (user, args, bot) ->
        @getGame @channel.name, (game) =>
            bot.say '[Game] ' + @str('show-game', @channel.name, game)
            
           
    cmdViewers: (user, args, bot) ->
        @getViewers @channel.name, (viewers) =>
            bot.say "[Viewers] " + @str('show-viewers', viewers)
            
            
    cmdViews: (user, args, bot) ->
        @getViews @channel.name, (views) =>
            bot.say "[Views] " + @str('show-views', views)
         
         
    cmdTitle: (user, args, bot) ->
        @getTitle @channel.name, (title) =>
            bot.say "[Title] " + @str('show-title', title)
            
         
    getGame: (chan, cb) ->
        @getData chan, (data) ->
            cb (data["game"] ? "N/A")
            
            
    getViewers: (chan, cb) ->
        @getData chan, (data) ->
            cb ("[Unavailable]")
            
            
    getViews: (chan, cb) ->
        @getData chan, (data) ->
            return cb "N/A" unless (chan = data["channel"])?
            cb ("[Unavailable]")
            
            
    getTitle: (chan, cb) ->
        @getData chan, (data) ->
            cb (data["status"] ? "N/A")
            
            
    getData: (chan, cb) ->
        cache.get chan.toLowerCase(), cb

    handle: (user, msg, bot) ->
        

exports.New = (channel) -> new JTV channel
