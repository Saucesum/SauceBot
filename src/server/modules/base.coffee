# SauceBot Module: Base

Sauce = require '../sauce'
db    = require '../saucedb'
trig  = require '../trigger'

io    = require '../ioutil'
vars  = require '../vars'

# Module description
exports.name        = 'Base'
exports.version     = '1.1'
exports.description = 'Global base commands such as !time and !saucebot'

io.module '[Base] Init'

# Base module
# - Handles:
#  !saucebot
#  !time
#  !test
#
class Base
    constructor: (@channel) ->
        @loaded = false

    load:->
        return if @loaded
        @loaded = true
        
        io.module "[Base] Loading for #{@channel.id}: #{@channel.name}"

        @channel.register  this, "saucebot", Sauce.Level.User,
            (user,args,bot) ->
              bot.say "[SauceBot] SauceBot v#{Sauce.Version} - Node #{process.version}"

        @channel.register  this, "test", Sauce.Level.Mod,
            (user,args,bot) ->
              bot.say 'Test command!' if user.op?

        @channel.register  this, "time", Sauce.Level.User,
            (user,args,bot) ->
              date = new Date()
              bot.say "[Time] #{vars.formatTime(date)}"
              

    unload:->
        return unless @loaded
        @loaded = false
        
        io.module "[Base] Unloading from #{@channel.id}: #{@channel.name}"
        myTriggers = @channel.listTriggers { module:this }
        @channel.unregister myTriggers...
        

    handle: (user, msg, bot) ->
        

exports.New = (channel) ->
    new Base channel
    
