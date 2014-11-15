# SauceBot Module: Timer

Sauce = require '../sauce'
db    = require '../saucedb'
io    = require '../ioutil'
tz    = require '../../common/time'

{ConfigDTO, HashDTO} = require '../dto'

{Module} = require '../module'

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
}


class Timer extends Module
    constructor: (@channel) ->
        super @channel
        @timers     = new HashDTO @channel, 'timers',     'name', 'time'
        @countdowns = new HashDTO @channel, 'countdowns', 'name', 'time'
        
 
    load: ->
        @registerHandlers()

        @timers.load()
        @countdowns.load()
        
        
    registerHandlers: ->
        @regCmd "timer",          Sauce.Level.Mod, @cmdTimerStart
        @regCmd "timer stop",     Sauce.Level.Mod, @cmdTimerStop
        @regCmd "countdown",      Sauce.Level.Mod, @cmdCountdownStart
        @regCmd "countdown stop", Sauce.Level.Mod, @cmdCountdownStop
                
        @regVar 'countdown', (user, args, cb) =>
            unless args? and (cdown = @countdowns.get args[0])?
                cb 'N/A'
            else
                time = cdown - Date.now()
                cb tz.formatTime time, args[1]
            
        @regVar 'timer', (user, args, cb) =>
            unless args? and (timer = @timers.get args[0])?
                cb 'N/A'
            else
                time = Date.now() - timer
                cb tz.formatTime time, args[1]

        # Register web update handlers
        @regActs {
            # Timer.timers()
            'timers': (user, params, res) =>
                res.send now: Date.now(), timers: @timers.get()

            # Timer.countdowns()
            'countdowns': (user, params, res) =>
                res.send now: Date.now(), countdowns: @countdowns.get()
        }

                
    cmdTimerStart: (user, args) =>
        unless args? and args[0]?
            return bot.say "[Timer] " + @str('err-invalid-name') + '. ' + @str('err-usage', '!timer <timer name>')
            
        name = args[0]
        @timers.add name, Date.now()
        bot.say "[Timer] " + @str('action-timer-started', name, '!timer stop ' + name)
        
        
    cmdTimerStop: (user, args) =>
        unless args? and (timer = @timers.get args[0])?
            return bot.say "[Timer] " + @str('err-timer') + '. ' + @str('err-usage', '!timer stop <timer name>')
            
        bot.say "[Timer] #{args[0]}: #{tz.timeToFullStr (Date.now() - timer)}"
        @timers.remove args[0]
        
        
    cmdCountdownStart: (user, args) =>
        unless args? and args[0]? and args[1]?
            return bot.say "[Countdown] " + @str('err-invalid-name') + '. ' + @str('err-usage', '!countdown <name> <target>')
        
        name   = args.shift()
        target = tz.strToTime args.join('')
        @countdowns.add name, Date.now() + target
        bot.say "[Countdown] " + @str('action-countdown-started', name, '!countdown stop ' + name)
        

    cmdCountdownStop: (user, args) =>
        unless args? and (timer = @countdowns.get args[0])?
            return bot.say "[Countdown] " + @str('err-countdown') + '. ' + @str('err-usage', '!countdown stop <name>')
        
        bot.say "[Countdown] " + @str('action-countdown-stopped', args[0], tz.timeToFullStr (timer - Date.now()))
        @countdowns.remove args[0]
            

exports.New = (channel) -> new Timer channel
