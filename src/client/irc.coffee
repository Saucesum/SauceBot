# SauceBot IRC Connector

irc  = require '../node/irc'
util = require 'util'
io   = require '../common/ioutil'
time = require '../common/time'

# Flood limits
DELAY        = 3
REPEAT_DELAY = 45

# Limits for the raw-queue
RAW_DELAY  = 3000
MAX_QUEUE  = 10
POLL_DELAY = 2000

class SauceIRC
    
    constructor: (@server, @username, @password) ->
        @channel = '#' + @server.toLowerCase()
        @enabled = true
        @handlers = {}
        
        # Cache
        @lastMessage = null
        @lastTime    = 0

        # Raw-queue
        @rawQueue = []
        @lastRaw = 0
        @rawPoller()


    rawPoller: =>
        if not @enabled
            setTimeout @rawPoller, POLL_DELAY * 10
        else
            now = Date.now()
            if @rawQueue.length and @lastRaw + RAW_DELAY < now
                msg = @rawQueue.shift()
                @bot?.say @channel, msg
                @lastRaw = now
                io.debug "Queued message sent: #{msg}"

            setTimeout @rawPoller, POLL_DELAY

    
    connect: ->
        @bot = new irc.Client "#{@server.toLowerCase()}.jtvirc.com", @username,
            debug          : false
            channels       : [@channel]
            userName       : @username
            realName       : @username
            password       : @password
            floodProtection: true
            stripColors    : true

        @bot.on cmd, cb for cmd, cb of @handlers
        @enabled = true


    disconnect: ->
        @bot.disconnect 'Client disconnected'
        @enabled = false
        
        
    on: (cmd, handler) ->
        if @bot?
            @bot.on cmd, handler
        @handlers[cmd] = handler


    say: (message) ->
        if @isCached message
            return io.debug "[IRC] Skipping: #{message}"
        
        @bot.say @channel, io.noise() + ' ' + message


    sayRaw: (message) ->
        now = Date.now()
        if @lastRaw + RAW_DELAY > now
            @rawQueue.push message
            @rawQueue.shift() until @rawQueue.length < MAX_QUEUE
            io.debug "Raw queued."
        else
            @bot.say @channel, message
            @lastRaw = now


    send: (code, args...) ->
        @bot.send code, args...


    isCached: (message) ->
        now = time.now()
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
