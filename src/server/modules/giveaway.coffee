# SauceBot Module: Giveaway

Sauce = require '../sauce'
db    = require '../saucedb'
trig  = require '../trigger'
vars  = require '../vars'

io    = require '../ioutil'

util = require 'util'

{Module} = require '../module'

# Basic information
exports.name        = 'Giveaway'
exports.description = 'Giveaway with random numbers'
exports.version     = '1.0'

# Specifies that this module is always active
exports.locked      = false

# These are the custom strings that can be changed by an administrator of the channel
exports.strings     = {
    'err-usage' : 'Usage: @1@'
    'str-max-num' : 'max number'
    'err-too-low' : "The max number you've picked (@1@) is too low"
    'str-giveaway': "The giveaway has started! Pick a number between 0 and @1@"
    'str-guessed': "The number has been guessed by @1@ and was @2@"
    'str-stop-giveaway': 'The giveaway has been stopped!'
}

class GiveAway extends Module
    constructor: (@channel) ->
        # The default constructor stores the associated Channel instance as
        # @channel, so it is passed on to the superclass.
        # If there is no module-specific constructor, then the channel will
        # be automatically stored as an instance variable.
        super @channel
        # Initialize any instance variables, etc.
        @randomNumber = 0
        @maxNumber = 0
        
    load: ->
        # Handle all data loading and initialization here, bearing in mind,
        # however, that this method may be called again to reload data,
        # although only after unload has been called.
        # Initialization may also include registering handlers, etc.
        @regCmd "giveaway", Sauce.Level.Mod, @cmdGiveaway


    handle: (user, msg, bot) ->
        if @maxNumber > 0
            m = /(\d+)/.exec(msg)
            if (m and parseInt(m[1], 10) == @randomNumber)
                @randomNumber = 0
                @maxNumber = 0
                return bot.say @str('str-guessed', user.name, m[1])


    cmdGiveaway: (user, args, bot) =>
        unless args[0]?
            return bot.say @str('err-usage', '!giveaway <max number>')

        if @maxNumber > 0 and args[0] == "stop"
            @maxNumber = 0
            @randomNumber = 0
            return bot.say @str('str-stop-giveaway')
        
        num = parseInt(args[0])

        if num < 2 or isNaN num
            return bot.say @str('err-too-low', num)

        @maxNumber = num
        @randomNumber = ~~(Math.random() * num)

        io.debug "The number is: " + @randomNumber

        return bot.say @str('str-giveaway', num)




exports.New = (channel) ->
    # Create and return a new instance of the module.
    new GiveAway channel
