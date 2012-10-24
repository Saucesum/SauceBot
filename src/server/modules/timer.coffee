# SauceBot Module: Timer

Sauce = require '../sauce'
db    = require '../saucedb'
io    = require '../ioutil'

{ConfigDTO, HashDTO} = require '../dto'


# Module description
exports.name        = 'Timer'
exports.version     = '1.0'
exports.description = 'Timer system'

exports.strings = {
    'err-usage'       : 'Usage: @1@'
    'err-invalid-name': 'Invalid name'
    'err-countdown'   : 'Invalid countdown'
    'err-timer'       : 'Invalid timer'

    'action-countdown-started': 'Countdown @1@ started. Cancel with: @2@'
    'action-countdown-stopped': '@1@: stopped at @2@ remaining'

    'action-timer-started': 'Timer @1@ started. Stop with @2@'

    # TODO: Add something for time units here... maybe.
}

# Time utility methods

timeRE = /(?:(\d+)\s*[dD]\w*)?\s*(?:(\d+)\s*[hHtT]\w*)?\s*(?:(\d+)\s*[mM]\w*)?\s*(?:(\d+)\s*[sS]\w*)?\s*/

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
 
 

timeToShortStr = (time) ->
    if time >= DAY
        days  = ~~( time / DAY)
        hours = ~~((time % DAY) / HOUR)
        return "#{days}d#{hours}h"
    
    if time >= HOUR
        hours   = ~~( time / HOUR)
        minutes = ~~((time % HOUR) / MINUTE)
        return "#{hours}h#{minutes}m"
        
    else
        minutes = ~~( time / MINUTE)
        seconds = ~~((time % MINUTE) / SECOND)
        return "#{minutes}m#{seconds}s"
        
    
timeToStr = (time) ->
    if time >= DAY
        days  = ~~( time / DAY)
        hours = ~~((time % DAY) / HOUR)
        return "#{word days, 'day'} #{word hours, 'hour'}"
    
    if time >= HOUR
        hours   = ~~( time / HOUR)
        minutes = ~~((time % HOUR) / MINUTE)
        return "#{word hours, 'hour'} #{word minutes, 'minute'}"
        
    else
        minutes = ~~( time / MINUTE)
        seconds = ~~((time % MINUTE) / SECOND)
        return "#{word minutes, 'minute'} #{word seconds, 'second'}"
        
        
timeToFullStr = (time) ->
    strs = []
    if time >= DAY
        days = ~~ (time / DAY)
        time %= DAY
        strs.push(word days, 'day') unless days is 0
    
    if time >= HOUR
        hours = ~~ (time / HOUR)
        time %= HOUR
        strs.push(word hours, 'hour') unless  hours is 0
        
    if time >= MINUTE
        minutes = ~~ (time / MINUTE)
        time %= MINUTE
        strs.push(word minutes, 'minute') unless minutes is 0
        
    if time >= SECOND
        seconds = ~~ (time / SECOND)
        strs.push (word seconds, 'second') unless seconds is 0
        
    return strs.join ' '


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
        
        @channel.vars.unregister 'timer'
        @channel.vars.unregister 'countdown'
        
        
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
                
        @channel.vars.register 'countdown', (user, args, cb) =>
            unless args? and (cdown = @countdowns.get args[0])?
                cb 'N/A'
            else
                time = cdown - Date.now()
                cb @formatTime time, args[1]
            
        @channel.vars.register 'timer', (user, args, cb) =>
            unless args? and (timer = @timers.get args[0])?
                cb 'N/A'
            else
                time = Date.now() - timer
                cb @formatTime time, args[1]
                
    formatTime: (time, format) ->
        fmt = format ? 'short'
        fmt = fmt.trim()
        
        if fmt is 'short'
            return timeToShortStr time
        if fmt in ['full', 'long']
            return timeToFullStr time
        else
            return timeToStr time
        
    
    cmdTimerStart: (user, args, bot) ->
        unless args? and args[0]?
            return bot.say "[Timer] " + @str('err-invalid-name') + '. ' + @str('err-usage', '!timer <timer name>')
            
        name = args[0]
        @timers.add name, Date.now()
        bot.say "[Timer] " + @str('action-timer-started', name, '!timer stop ' + name)
        
        
    cmdTimerStop: (user, args, bot) ->
        unless args? and (timer = @timers.get args[0])?
            return bot.say "[Timer] " + @str('err-timer') + '. ' + @str('err-usage', '!timer stop <timer name>')
            
        bot.say "[Timer] #{args[0]}: #{timeToFullStr (Date.now() - timer)}"
        @timers.remove args[0]
        
        
    cmdCountdownStart: (user, args, bot) ->
        unless args? and args[0]? and args[1]?
            return bot.say "[Countdown] " + @str('err-invalid-name') + '. ' + @str('err-usage', '!countdown <name> <target>')
        
        name   = args.shift()
        target = strToTime args.join('')
        @countdowns.add name, Date.now() + target
        bot.say "[Countdown] " + @str('action-countdown-started', name, '!countdown stop ' + name)
        
    cmdCountdownStop: (user, args, bot) ->
        unless args? and (timer = @countdowns.get args[0])?
            return bot.say "[Countdown] " + @str('err-countdown') + '. ' + @str('err-usage', '!countdown stop <name>')
        
        bot.say "[Countdown] " + @str('action-countdown-stopped', args[0], timeToFullStr (timer - Date.now()))
        @countdowns.remove args[0]
            
        
    handle: (user, msg, bot) ->
        

exports.New = (channel) -> new Timer channel
