# SauceBot Module: Last.FM

Sauce = require '../sauce'
db    = require '../saucedb'
io    = require '../ioutil'

request = require 'request'

{ConfigDTO, HashDTO} = require '../dto' 


# Module description
exports.name        = 'LastFM'
exports.version     = '1.0'
exports.description = 'Last.FM API'

CACHE_TIMEOUT = 45 * 1000

api_key  = 'b25b959554ed76058ac220b7b2e0a026'

getURL = (username) ->
    "http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=#{username}&api_key=#{api_key}&format=json&limit=1"


class LastFM
    constructor: (@channel) ->
        
        @loaded = false
        @cache = {}
        
                
    load: ->
        io.module "[Last.FM] Loading for #{@channel.id}: #{@channel.name}"

        @registerHandlers() unless @loaded
        @loaded = true

        
    unload: ->
        return unless @loaded
        @loaded = false
        
        io.module "[Last.FM] Unloading from #{@channel.id}: #{@channel.name}"
        myTriggers = @channel.listTriggers { module:this }
        @channel.unregister myTriggers...

        
    registerHandlers: ->
        @channel.register this, "lastfm", Sauce.Level.User,
            (user,args,bot) =>
                @cmdLastFM user, args, bot
        
        
    cmdLastFM: (user, args, bot) ->
        unless args[0]?
            return bot.say '[last.fm] Usage: !lastfm <username>'
            
        # Filter out bad characters
        name = args[0].replace /[^-a-zA-Z_0-9]/g, ''
            
        @getSong name, (song) ->
            bot.say "[last.fm] #{name}: #{song}"
            
            
    getSong: (name, cb) ->
        cached = @getCachedSong name
        return cb cached if cached?
        
        request {url: getURL(name), timeout: 2000}, (err, resp, json) =>
            song = @parseSongJSON json
            @setCachedSong name, song
            cb song
       
        
    getCachedSong: (name) ->
        lc = name.toLowerCase()
        return unless cache = @cache[lc]?

        expire = cache.expire
        if expire > Date.now()
            delete @cache[lc]
        else
            return cache.value


    parseSongJSON: (json) ->
        try
            data = JSON.parse json
            return 'N/A' unless data? and data.recenttracks?
            
            artist = data.recenttracks.track.artist['#text']
            track  = data.recenttracks.track.name
            
            return "#{artist} - #{track}"
            
        catch err
            return 'N/A'


    setCachedSong: (name, song) ->
        @cache[name.toLowerCase()] =
            expire: Date.now() + CACHE_TIMEOUT
            value : song

    handle: (user, msg, bot) ->
        

exports.New = (channel) -> new LastFM channel
