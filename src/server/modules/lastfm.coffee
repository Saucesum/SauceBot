# SauceBot Module: Last.FM

Sauce = require '../sauce'
db    = require '../saucedb'
io    = require '../ioutil'

{Cache, WebCache} = require '../cache'

request = require 'request'
util    = require 'util'

{ConfigDTO, HashDTO} = require '../dto'
{Module} = require '../module'

# Module description
exports.name        = 'LastFM'
exports.version     = '1.0'
exports.description = 'Last.FM API'

exports.strings = {
    'err-usage'  : 'Usage: @1@'
    'playing-now': 'Now playing - @1@: @2@'
}

CACHE_TIMEOUT = 30 * 1000

API_KEY = Sauce.API.LastFM

getURL = (username) ->
    "http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=#{username}&api_key=#{API_KEY}&format=json&limit=1&time=#{Date.now()}"

# The song cache is global, since there's really no need to have it per module
# instance
songCache = new WebCache getURL, CACHE_TIMEOUT

class LastFM extends Module
    load: ->
        @registerHandlers()

        
    registerHandlers: ->
        @regCmd "lastfm", Sauce.Level.Mod, @cmdLastFM

        @regVar 'lastfm', (user, args, cb) =>
            unless args[0]?
                cb 'N/A'
            else
                # Filter out bad characters
                name = args[0].replace /[^-a-zA-Z_0-9]/g, ''
                @getSong name, (song) ->
                    cb song
        
        
    cmdLastFM: (user, args) =>
        unless args[0]?
            return @bot.say @str('err-usage', '!lastfm <username>')
            
        # Filter out bad characters
        name = args[0].replace /[^-a-zA-Z_0-9]/g, ''
            
        @getSong name, (song) =>
            @bot.say "[last.fm] " + @str('playing-now', name, song)
            
    
    getSong: (name, cb) ->
        songCache.get name, (song) =>
            cb @parseSong song


    parseSong: (data) ->
        try
            return 'N/A' unless data? and data.recenttracks?
            
            track = data.recenttracks.track
            track = track[0] if track[0]?
            
            artist = track.artist['#text'] ? track.artist["name"]
            track  = track.name
            
            return "#{artist} - #{track}"
            
        catch err
            return 'N/A'


exports.New = (channel) -> new LastFM channel
