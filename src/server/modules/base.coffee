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

    load:->
        io.module "[Base] Loading for #{@channel.id}"

        @channel.register  this, "saucebot", Sauce.Level.User,
            (user,args,sendMessage) ->
              sendMessage '[SauceBot] SauceBot version 3.1 - Node.js'

        @channel.register  this, "test", Sauce.Level.Mod,
            (user,args,sendMessage) ->
              sendMessage 'Test command!' if user.op?

        @channel.register  this, "time", Sauce.Level.User,
            (user,args,sendMessage) ->
              date = new Date()
              sendMessage "[Time] #{vars.formatTime(date)}"

    unload:->
        myTriggers = @channel.listTriggers { module:this }
        @channel.unregister myTriggers...

    handle: (user, msg, sendMessage) ->
        

exports.New = (channel) ->
    new Base channel
    
