# SauceBot Module: JTV API

Sauce = require '../sauce'
db    = require '../saucedb'
io    = require '../ioutil'

request = require 'request'
util    = require 'util'

{ConfigDTO, HashDTO} = require '../dto' 


# Module description
exports.name        = 'JTV'
exports.version     = '1.0'
exports.description = 'JTV API'

exports.strings = {
    'show-game'   : '@1@ is playing @2@'
    'show-viewers': 'There are currently @1@ viewers!'
    'show-views'  : 'This channel has been viewed @1@ times!'
    'show-title'  : '@1@'
}

CACHE_TIMEOUT = 2 * 60 * 1000

class JTV
    constructor: (@channel) ->
        
        @loaded = false
        @cache  = {}
        @expire = 0
        
        @url    = "http://api.justin.tv/api/stream/list.json?channel=#{@channel.name}"
        
                
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
            usage = '$(jtv (game|viewers|views|title)'
            unless args[0]?
                cb usage
            else
                switch args[0]
                    when 'game'    then @getGame cb
                    when 'viewers' then @getViewers cb
                    when 'views'   then @getViews cb
                    when 'title'   then @getTitle cb
                    else cb usage

        
    cmdGame: (user, args, bot) ->
        @getGame (game) =>
            bot.say '[Game] ' + @str('show-game', @channel.name, game)
            
           
    cmdViewers: (user, args, bot) ->
        @getViewers (viewers) =>
            bot.say "[Viewers] " + @str('show-viewers', viewers)
            
            
    cmdViews: (user, args, bot) ->
        @getViews (views) =>
            bot.say "[Views] " + @str('show-views', views)
         
         
    cmdTitle: (user, args, bot) ->
        @getTitle (title) =>
            bot.say "[Title] " + @str('show-title', title)
            
         
    getGame: (cb) ->
        @getData (data) ->
            cb (data["meta_game"] ? "N/A")
            
            
    getViewers: (cb) ->
        @getData (data) ->
            cb (data["channel_count"] ? "N/A")
            
            
    getViews: (cb) ->
        @getData (data) ->
            return cb "N/A" unless (chan = data["channel"])?
            cb (chan["views_count"] ? "N/A")
            
            
    getTitle: (cb) ->
        @getData (data) ->
            cb (data["title"] ? "N/A")
            
            
    getData: (cb) ->
        if @isCached()
            console.log "[JTV] Cached data"
            return cb @cache
        
        request {url: @url, timeout: 2000}, (err, resp, json) =>
            data = @parseJSON json
            @setCache data
            cb data
       
        
    isCached: -> @expire > Date.now()

    parseJSON: (json) ->
        try
            data = JSON.parse json
            return {} unless data? and data[0]?
            return data[0]         
            
        catch err
            return {}


    setCache: (data) ->
        @cache  = data
        @expire = Date.now() + CACHE_TIMEOUT
        

    handle: (user, msg, bot) ->
        

exports.New = (channel) -> new JTV channel
