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

        @channel.register  this, "saucebot", Sauce.Level.User,
            (user,args,bot) ->
              bot.say "[SauceBot] SauceBot v#{Sauce.Version} by Ravn_TM - Node #{process.version}"

        @channel.register  this, "test", Sauce.Level.Mod,
            (user,args,bot) ->
              bot.say 'Test command!' if user.op?

        @channel.register  this, "time", Sauce.Level.User,
            (user,args,bot) ->
              date = new Date()
              bot.say "[Time] #{vars.formatTime(date)}"

        # Test
        @channel.register this, "var", Sauce.Level.Mod,
            (user, args, bot) =>
                return unless args
                bot.say "[Vars] " + @channel.vars.parse user, args.join ' '

        @channel.register this, "calc", Sauce.Level.Mod,
            (user, args, bot) =>
                return unless args
                txt = args.join ''
                math = txt.replace(/[^()\d*\/+-=\w]/g, '')
                try
                    bot.say vm.runInContext math, @sandbox, "#{@channel.name}.vm"
                catch error
                    bot.say "[Calc] Invalid expression: #{math}"
                
              

    unload:->
        return unless @loaded
        @loaded = false
        
        io.module "[Base] Unloading from #{@channel.id}: #{@channel.name}"
        myTriggers = @channel.listTriggers { module:this }
        @channel.unregister myTriggers...
        

    handle: (user, msg, bot) ->
        

exports.New = (channel) ->
    new Base channel
    
