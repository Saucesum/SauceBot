# SauceBot Module: Timer

Sauce = require '../sauce'
db    = require '../saucedb'
io    = require '../ioutil'

{ConfigDTO, HashDTO} = require '../dto' 


# Module description
exports.name        = 'Timer'
exports.version     = '1.0'
exports.description = 'Timer system (unfinished - do not use)'
exports.locked      = true

# Time utility methods

timeRE = /(?:(\d+)\s*[dD]\w*?)?\s*(?:(\d+)\s*[hHtT]\w*?)?\s*(?:(\d+)\s*[mM]\w*?)?\s*(?:(\d+)\s*[sS]\w*?)?\s*/

strToTime = (str) ->
    return '' unless m = timeRE.exec str
    days    = parseInt(m[1] ? 0, 10)
    hours   = parseInt(m[2] ? 0, 10)
    minutes = parseInt(m[3] ? 0, 10)
    seconds = parseInt(m[4] ? 0, 10)
    ms = 1000 * (seconds + 60 * (minutes + 60 * (hours + 24 * days)))
    
    
    
SECOND = 1000
MINUTE = 60 * SECOND
HOUR   = 60 * MINUTE
DAY    = 24 * HOUR
    
word = (num, str) ->
    switch num
        when 0
            ''
        when 1
            num + ' ' + str
        else
            num + ' ' + str + 's'
            
    
timeToStr = (time) ->
    if time >= DAY
        days  = Math.floor( time / DAY)
        hours = Math.floor((time % DAY) / HOUR)
        return "#{word days, 'day'} #{word hours, 'hour'}"
    
    if time >= HOUR
        hours   = Math.floor( time / HOUR)
        minutes = Math.floor((time % HOUR) / MINUTE)
        return "#{word hours, 'hour'} #{word minutes, 'minute'}"
        
    else
        minutes = Math.floor( time / MINUTE)
        seconds = Math.floor((time % MINUTE) / SECOND)
        return "#{word minutes, 'minute'} #{word seconds, 'second'}"
        

class Timer
    constructor: (@channel) ->
        @timers     = new HashDTO @channel, 'timers',     'name', 'time'
        @countdowns = new HashDTO @channel, 'countdowns', 'name', 'time'
        
        @loaded = false
        
                
    load: ->
        io.module "[Timer] Loading for #{@channel.id}: #{@channel.name}"

        @registerHandlers() unless @loaded
        @loaded = true

        @timers.load()
        @countdowns.load()
        
        
    unload: ->
        return unless @loaded
        @loaded = false
        
        io.module "[Timer] Unloading from #{@channel.id}: #{@channel.name}"
        myTriggers = @channel.listTriggers { module:this }
        @channel.unregister myTriggers...
        
        
    registerHandlers: ->
        @channel.register this, "timer",          Sauce.Level.Mod,
            (user,args,bot) =>
                @cmdTimerStart user, args, bot
                
        @channel.register this, "timer stop",     Sauce.Level.Mod,
            (user,args,bot) =>
                @cmdTimerStop user, args, bot
                
        @channel.register this, "countdown",      Sauce.Level.Mod,
            (user,args,bot) =>
                @cmdCountdownStart user, args, bot
                
        @channel.register this, "countdown stop", Sauce.Level.Mod,
            (user,args,bot) =>
                @cmdCountdownStop user, args, bot
                
        @channel.vars.register 'countdown', (user, args) =>
            return "N/A" unless args? and @countdowns.get()[args[0]]?
            now = Date.now()
            
            
                
        
    
    cmdTimerStart: (user, args, bot) ->
        # TODO !timer <name> 
        
        
    cmdTimerStop: (user, args, bot) ->
        # TOOD !timer stop <name>
        
        
    cmdCountdownStart: (user, args, bot) ->
        # TODO !countdown <name> <strToTime()>
        
        
    cmdCountdownStop: (user, args, bot) ->
        # TODO !countdown stop <name>
        
        
            
        
    handle: (user, msg, bot) ->
        

exports.New = (channel) -> new Timer channel
