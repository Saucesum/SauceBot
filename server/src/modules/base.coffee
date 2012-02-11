# SauceBot Module: Base

Sauce = require '../sauce'
db    = require '../saucedb'

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
        @handlers =
            saucebot: ->
                '[SauceBot] SauceBot version 3.1 - Node.js'
                
            test: (user) ->
                'Test command!' if user.op?
                
            time: ->
                date = new Date
                "[Time] #{date.getHours()}:#{date.getMinutes()}"
        
        
    load:->
        # Nothing to load
        
        
    handle: (user, command, args, sendMessage) ->
        handler = @handlers[command]
        
        if (handler?)
            result = handler(user, args)
            sendMessage result if result?

exports.New = (channel) ->
    new Base channel
    