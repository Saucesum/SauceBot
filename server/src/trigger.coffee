# SauceBot Trigger Utilities


db = require './saucedb'
io = require './ioutil'

exports.PRI_TOP   = 0  # Reserved for what, if anything, needs it.
exports.PRI_HIGH  = 1  # Could be used for sub commands, like '!vm reset'
exports.PRI_MID   = 2  # For simple commands, like '!time'
exports.PRI_LOW   = 3  # For greedy commands, like counter creation.

# Creates a trigger that matches !name followed by 0 or more words
exports.SimpleTrigger = (module, name, callback) ->
    new Trigger module,
                PRI_MID,
                new RegExp "^!#{name}( .*)?$",
                callback

class Trigger
    constructor: (@module, @priority, @pattern, @execute) ->
        # Constructs the Trigger

    matches: (msg) ->
        msg.match @pattern


exports.Trigger = Trigger


