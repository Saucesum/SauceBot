# SauceBot IRC Connector

irc = require '../node/irc'
util = require 'util'
io  = require '../common/ioutil'

# Flood limits
DELAY        = 3
REPEAT_DELAY = 45

class SauceIRC
    constructor: (@server, @username, @password) ->
        @channel = '#' + @server.toLowerCase()
        
        # Cache
        @lastMessage = null
        @lastTime    = 0

    
    connect: ->
        @bot = new irc.Client "#{@server}.jtvirc.com", @username,
            debug          : false
            channels       : [@channel]
            userName       : @username
            realName       : @username
            password       : @password
            floodProtection: true
            stripColors    : true


    disconnect: ->
        @bot.disconnect 'Client disconnected'
        
        
    on: (cmd, handler) ->
        @bot.on cmd, handler


    say: (message) ->
        if @isCached message
            return io.debug "[IRC] Skipping: #{message}"
        
        @sayRaw io.noise() + ' ' + message


    sayRaw: (message) ->
        @bot.say @channel, message


    isCached: (message) ->
        now = io.now()
        if @sinceLast(now, DELAY) or (@sinceLast(now, REPEAT_DELAY) and (message is @lastMessage))
            return true
            
        @lastMessage = message
        @lastTime    = now
        false
            

    sinceLast: (now, time) ->
        @lastTime + time > now
        
        
    setDebug: (state) ->
        @bot.opt.debug = state


exports.SauceIRC = SauceIRC