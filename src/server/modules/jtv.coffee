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

CACHE_TIMEOUT = 2 * 60 * 1000

class JTV
    constructor: (@channel) ->
        
        @loaded = false
        @cache  = {}
        @expire = 0
        
        @url    = "http://api.justin.tv/api/stream/search/#{@channel.name}.json"
        
                
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
        @channel.register this, "game", Sauce.Level.User,
            (user,args,bot) =>
                @cmdGame user, args, bot

        @channel.register this, "viewers", Sauce.Level.User,
            (user,args,bot) =>
                @cmdViewers user, args, bot
        
        @channel.register this, "views", Sauce.Level.User,
            (user,args,bot) =>
                @cmdViews user, args, bot
        
        @channel.register this, "title", Sauce.Level.User,
            (user,args,bot) =>
                @cmdTitle user, args, bot
        
        
    cmdGame: (user, args, bot) ->
        @getGame (game) =>
            bot.say "[Game] #{@channel.name} is playing #{game}"
            
           
    cmdViewers: (user, args, bot) ->
        @getViewers (viewers) =>
            bot.say "[Viewers] There are currently #{viewers} viewers!"
            
            
    cmdViews: (user, args, bot) ->
        @getViews (views) =>
            bot.say "[Views] This channel has been viewed #{views} times!"
         
         
    cmdTitle: (user, args, bot) ->
        @getTitle (title) =>
            bot.say "[Title] #{title}"
            
         
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
