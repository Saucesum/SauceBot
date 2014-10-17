# SauceBot IRC Connector

irc  = require '../../node_modules/irc'
util = require 'util'
io   = require '../common/ioutil'
time = require '../common/time'

# Flood limits
DELAY        = 3000
REPEAT_DELAY = 45000

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
        @lastRawMessage = null
        @lastRaw = 0
        @rawPoller()


    rawPoller: =>
        if not @enabled
            setTimeout @rawPoller, POLL_DELAY * 10
        else
            now = Date.now()
            if @rawQueue.length and @lastRaw + RAW_DELAY < now
                @popRawQueue now

            setTimeout @rawPoller, POLL_DELAY


    popRawQueue: (now) ->
        msg = @rawQueue.shift()
        unless msg is @lastRawMessage
            @bot?.say @channel, msg
            @lastRaw        = now
            @lastTime       = now
            @lastRawMessage = msg
            io.debug "Queued message sent: #{msg}"

    
    connect: ->
        @bot = new irc.Client "irc.twitch.tv", @username,
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

        if @rawQueue.length is 0 and @lastRaw + RAW_DELAY < now
            # Nothing in the queue.
            @bot.say @channel, message
            @lastRaw  = now
            @lastTime = now
            return

        unless message in @rawQueue
            # Queue message for later.
            @rawQueue.push message
            @rawQueue.shift() until @rawQueue.length < MAX_QUEUE
            io.debug "Raw queued."


    send: (code, args...) ->
        @bot.send code, args...


    isCached: (message) ->
        now = Date.now()
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
