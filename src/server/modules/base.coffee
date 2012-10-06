# SauceBot Module: Base

Sauce = require '../sauce'
db    = require '../saucedb'
trig  = require '../trigger'

io    = require '../ioutil'
vars  = require '../vars'

vm    = require 'vm'
util  = require 'util'

# Module description
exports.name        = 'Base'
exports.version     = '1.2'
exports.description = 'Global base commands'
exports.locked      = true

exports.strings = {
    # Help messages
    'help-basic'    : 'For urgent help, use @1@. Otherwise, tweet @RavnTM'
    'help-requested': 'SauceBot helpers have been alerted and should arrive soon.'
    'help-incoming' : 'SauceBot helper @1@ incoming'
    
    # Misc messages
    'math-invalid'  : 'Invalid expression: @1@'
}

io.module '[Base] Init'

# Base module
# - Handles:
#  !saucebot
#  !time
#  !test
#  !calc
#
class Base
    constructor: (@channel) ->
        @loaded = false
        
        mathValues =
            e: 2.718281828459045235360
            pi: 3.141592
        
        @sandbox = vm.createContext mathValues

    load:->
        return if @loaded
        @loaded = true
        
        io.module "[Base] Loading for #{@channel.id}: #{@channel.name}"

        @channel.register this, "saucebot", Sauce.Level.User,
            (user,args,bot) ->
              bot.say "[SauceBot] SauceBot v#{Sauce.Version} by @RavnTM - CoffeeScript/Node.js"

        @channel.register this, "test", Sauce.Level.Mod,
            (user,args,bot) ->
              bot.say "Test command! #{user.name} - #{Sauce.LevelStr user.op}"
              
        @channel.register this, "admtest", Sauce.Level.Admin,
            (user,args,bot) ->
              bot.say 'Admin test command!'

        @channel.register this, "saucetime", Sauce.Level.User,
            (user,args,bot) ->
              date = new Date()
              tz = -date.getTimezoneOffset()/60
              bot.say "[SauceTime] #{vars.formatTime(date)} GMT #{if tz > 0 then '+' + tz else tz}"
              
        @channel.register this, "help", Sauce.Level.Mod,
            (user,args,bot) =>
                db.addData 'helprequests', ['chanid', 'time', 'user', 'reason'], [[
                    @channel.id,
                    ~~(Date.now()/1000),
                    user.name.toLowerCase(),
                    args.join ' '
                ]]
                if args.length > 0
                    bot.say "[Help] " + @str('help-requested')
                else
                    bot.say "[Help] " + @str('help-basic', '!help <message>')

        # Test
        @channel.register this, "var", Sauce.Level.Mod,
            (user, args, bot) =>
                return unless args
                raw = args.join ' '
                @channel.vars.parse user, raw, raw, (parsed) ->
                    bot.say "[Vars] #{parsed}"

        @channel.register this, "calc", Sauce.Level.Mod,
            (user, args, bot) =>
                return unless args
                txt = args.join ''
                math = txt.replace(/[^()\d*\/+-=\w]/g, '')
                try
                    bot.say math + "=" + (vm.runInContext math, @sandbox, "#{@channel.name}.vm")
                catch error
                    bot.say "[Calc] " + @str('math-invalid', math)
                
              

    unload:->
        return unless @loaded
        @loaded = false
        
        io.module "[Base] Unloading from #{@channel.id}: #{@channel.name}"
        myTriggers = @channel.listTriggers { module:this }
        @channel.unregister myTriggers...
        

    handle: (user, msg, bot) ->
        

exports.New = (channel) ->
    new Base channel
    
