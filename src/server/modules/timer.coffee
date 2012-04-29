# SauceBot Module: Timer

Sauce = require '../sauce'
db    = require '../saucedb'
io    = require '../ioutil'

{ConfigDTO, HashDTO} = require '../dto' 


# Module description
exports.name        = 'Timer'
exports.version     = '1.0'
exports.description = 'Timer system'

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
        
        
timeToFullStr = (time) ->
    strs = []
    if time >= DAY
        days = Math.floor time / DAY
        time %= DAY
        strs.push(word days, 'day') unless days is 0
    
    if time >= HOUR
        hours = Math.floor time / HOUR
        time %= HOUR
        strs.push(word hours, 'hour') unless  hours is 0
        
    if time >= MINUTE
        minutes = Math.floor time / MINUTE
        time %= MINUTE
        strs.push(word minutes, 'minute') unless minutes is 0
        
    if time >= SECOND
        seconds = Math.floor time / SECOND
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
                
        @channel.vars.register 'countdown', (user, args) =>
            return "N/A" unless args? and (cdown = @countdowns.get args[0])?
            return timeToStr (cdown - Date.now())
            
        @channel.vars.register 'timer', (user, args) =>
            return "N/A" unless args? and (timer = @timers.get args[0])?
            return timeToFullStr (Date.now() - timer)
        
    
    cmdTimerStart: (user, args, bot) ->
        unless args? and args[0]?
            return bot.say "[Timer] Invalid name. Usage: !timer <timername>"
            
        name = args[0]
        @timers.add name, Date.now()
        bot.say "[Timer] Timer #{name} started. Stop with !timer stop #{name}"
        
        
    cmdTimerStop: (user, args, bot) ->
        unless args? and (timer = @timers.get args[0])?
            return bot.say "[Timer] Invalid timer. Usage: !timer stop <timername>"
            
        bot.say "[Timer] #{args[0]}: #{timeToFullStr (Date.now() - timer)}"
        @timers.remove args[0]
        
        
    cmdCountdownStart: (user, args, bot) ->
        unless args? and args[0]? and args[1]?
            return bot.say "[Countdown] Invalid name. Usage: !countdown <name> <target>"
        
        name   = args.shift()
        target = strToTime args.join('')
        @countdowns.add name, Date.now() + target
        bot.say "[Countdown] Countdown #{name} started! Cancel with !countdown stop #{name}"
        
    cmdCountdownStop: (user, args, bot) ->
        unless args? and (timer = @countdowns.get args[0])?
            return bot.say "[Countdown] Invalid countdown. Usage: !countdown stop <name>"
        
        bot.say "[Countdown] #{args[0]}: stopped at #{timeToFullStr (timer - Date.now())} remaining"
        @countdowns.remove args[0]
            
        
    handle: (user, msg, bot) ->
        

exports.New = (channel) -> new Timer channel
