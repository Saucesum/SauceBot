# SauceBot Trigger Utilities


db = require './saucedb'
io = require './ioutil'

PRI_TOP   = 0  # Reserved for what, if anything, needs it.
PRI_HIGH  = 1  # Could be used for sub commands, like '!vm reset'
PRI_MID   = 2  # For simple commands, like '!time'
PRI_LOW   = 3  # For greedy commands, like counter creation.

# Creates a trigger that matches !name followed by 0 or more words
exports.SimpleTrigger = (module, name, callback) ->
    new Trigger module,
                exports.PRI_MID,
                new RegExp("^!#{name}(?:\s+(.+))?$"),
                callback

class Trigger
    constructor: (@module, @priority, @pattern, @execute) ->
        # Constructs the Trigger

    matches: (msg) ->
        msg.match @pattern

exports.PRI_TOP   = PRI_TOP
exports.PRI_HIGH  = PRI_HIGH
exports.PRI_MID   = PRI_MID
exports.PRI_LOW   = PRI_LOW

exports.Trigger = Trigger


