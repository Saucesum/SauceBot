# SauceBot Module: Base

Sauce = require '../sauce'
db    = require '../saucedb'
trig  = require '../trigger'

io    = require '../ioutil'

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
        @channel.register trig.SimpleTrigger this, "saucebot", ->
          '[SauceBot] SauceBot version 3.1 - Node.js'

        @channel.register trig.SimpleTrigger this, "test", ->
            'Test command!' if user.op?

        @channel.register trig.SimpleTrigger this, "time", ->
            "[Time] #{date.getHours()}:#{date.getMinutes()}"

    handle: (user, command, args, sendMessage) ->
        

exports.New = (channel) ->
    new Base channel
    
