# SauceBot Module: Giveaway
io    = require '../ioutil'
{Module} = require '../module'

# Basic information
exports.name        = 'Giveaway'
exports.description = 'Giveaway with random numbers'
exports.version     = '1.0'

# Specifies that this module is always active
exports.locked      = false

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
        super @channel

        @randomNumber = 0
        @maxNumber = 0
        
    load: ->
        @regCmd "giveaway", Sauce.Level.Mod, @cmdGiveaway


    handle: (user, msg) ->
        if @maxNumber > 0
            m = /(\d+)/.exec(msg)
            if (m and parseInt(m[1], 10) == @randomNumber)
                @randomNumber = 0
                @maxNumber = 0
                return bot.say @str('str-guessed', user.name, m[1])


    cmdGiveaway: (user, args) =>
        unless args[0]?
            return bot.say @str('err-usage', '!giveaway <max number>')

        if @maxNumber > 0 and args[0] == "stop"
            @maxNumber = 0
            @randomNumber = 0
            return bot.say @str('str-stop-giveaway')
        
        num = parseInt(args[0], 10)

        if num < 2 or isNaN num
            return bot.say @str('err-too-low', num)

        @maxNumber = num
        @randomNumber = ~~(Math.random() * num)

        io.debug "The number is: " + @randomNumber

        return bot.say @str('str-giveaway', num)




exports.New = (channel) ->
    new GiveAway channel
