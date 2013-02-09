# SauceBot Module: AutoCommercial

Sauce = require '../sauce'
db    = require '../saucedb'
io    = require '../ioutil'
util  = require 'util'

{ConfigDTO} = require '../dto'
{Module   } = require '../module'
{TokenJar } = require '../../common/oauth'

# Module description
exports.name        = 'AutoCommercial'
exports.version     = '1.1'
exports.description = 'Automatic commercials for twitch.tv partners'
exports.ignore      = true

exports.strings = {
    'config-enable'    : 'Enabled'
    'config-disable'   : 'Disabled'
    'action-commercial': 'Commercial! Thank you for supporting @1@! <3'
    'action-failed'    : 'Could not run a commercial. Please contact SauceBot support.'
    'action-delay'     : 'Minimum delay set to @1@ minutes.'
    'action-messages'  : 'Minimum number of messages set to @1@.'
}

io.module '[AutoCommercial] Init'

oauth = new TokenJar Sauce.API.Twitch, Sauce.API.TwitchToken


# Constants
MINIMUM_DELAY    = 15
MINIMUM_MESSAGES = 15

COMMERCIAL_DELAY = 10 * 60 * 1000

DURATIONS = [30, 60, 90]

class AutoCommercial extends Module
    constructor: (@channel) ->
        super @channel
        @comDTO = new ConfigDTO @channel, 'autocommercial', ['state', 'delay', 'messages']
        
        @messages = []
        @lastTime = Date.now()
        
        
    load: ->
        @registerHandlers()
        @comDTO.load()
        

    registerHandlers: ->
        # !commercial on - Enable auto-commercials
        @regCmd "commercial on", Sauce.Level.Admin, @cmdEnableCommercial
        
        # !commercial off - Disable auto-commercials
        @regCmd "commercial off", Sauce.Level.Admin, @cmdDisableCommercial

        # !commercial delay <minutes> - Set delay
        @regCmd "commercial delay", Sauce.Level.Admin, @cmdDelay

        # !commercial messages <minutes> - Set messages
        @regCmd "commercial messages", Sauce.Level.Admin, @cmdMessages

        # !commercial <time> - Runs a commercial
        @regCmd "commercial", Sauce.Level.Admin, @cmdCommercial
        
        # Variables $(commercial state|delay|messages)
        @regVar "commercial", @varCommercial

        # Register interface actions
        @regActs {
            'config': @actConfig
        }


    # Action handler for "config"
    # AutoCommercial.config([state|delay|messages]*)
    actConfig: (user, params, res) =>
        {state, delay, messages} = params

        unless state? or delay? or messages?
            return res.send @comDTO.get()

        unless user.isMod @channel, Sauce.Level.Admin
            return res.error "You are not authorized to alter AutoCommercial (admins only)"

        # State - 1 or 0
        if state?.length
            val = if (val = parseInt state, 10) then 1 else 0
            @comDTO.add 'state', val
            @lastTime = Date.now()

        # Delay in minutes - any number over MINIMUM_DELAY
        if delay?.length then @clampMinimums 'delay', delay

        # Messages limit - any number over MINIMUM_MESSAGES
        if messages?.length then @clampMinimums 'messages', messages

        res.send @comDTO.get()


    cmdEnableCommercial: (user, args, bot)  =>
        @comDTO.add 'state', 1
        @lastTime = Date.now()
        @say bot, @str('config-enable')
    
    
    cmdDisableCommercial: (user, args, bot) =>
        @comDTO.add 'state', 0
        @say bot, @str('config-disable')


    cmdDelay: (user, args, bot) =>
        num = @clampMinimums 'delay', args[0]
        @say bot, @str('action-delay', num)


    cmdMessages: (user, args, bot) =>
        num = @clampMinimums 'messages', args[0]
        @say bot, @str('action-messages', num)


    cmdCommercial: (user, args, bot) =>
        if @lastTime < COMMERCIAL_DELAY then return
        duration = parseInt(args[0], 10)
        duration = DURATIONS[0] unless duration in DURATIONS

        @lastTime = Date.now()

        # TODO implement time
        oauth.post "/channels/#{@channel.name}/commercial", (resp, body) =>
            # "204 No Content" if successful.
            if resp.statusCode is 204
                bot.say @str('action-commercial', @channel.name)
            else
                bot.say @str('action-failed')
        

    clampMinimums: (field, val) ->
        @comDTO.add field, parseInt val, 10

        for key, min of {
                'messages': MINIMUM_MESSAGES
                'delay'   : MINIMUM_DELAY
                }
            value = @comDTO.get key
            if isNaN(value) or value < min
                @comDTO.add key, min

        @comDTO.get field
   

    varCommercial: (user, args, cb) =>
        arg = args[0] ? 'state'
        
        cb switch arg
            when 'state'
                if @comDTO.get 'state' then 'Enabled' else 'Disabled'
            when 'messages'
                @comDTO.get 'messages'
            when 'delay'
                @comDTO.get 'delay'
            else
                '$(commercial state|messages|delay)'
             

    updateMessagesList: (now) ->
        delay = @comDTO.get 'delay'
        delay = MINIMUM_DELAY if delay < MINIMUM_DELAY
        limit = now - (delay * 60 * 1000)
        
        @messages.push now
        @messages = (message for message in @messages when message > limit)
        
        
    messagesSinceLast: ->
        @messages.length


    handle: (user, msg, bot) ->
        return unless @comDTO.get 'state'
        now = Date.now()
        
        @updateMessagesList now
        msgsLimit = @comDTO.get 'messages'
        msgsLimit = MINIMUM_MESSAGES if msgsLimit < MINIMUM_MESSAGES
        
        delay = @comDTO.get 'delay'
        delay = MINIMUM_DELAY if delay < MINIMUM_DELAY
        
        return unless @messagesSinceLast() >= msgsLimit and (now - @lastTime > (delay * 60 * 1000))
        
        oauth.post "/channels/#{@channel.name}/commercial", (resp, body) =>
            # "204 No Content" if successful.
            bot.say @str('action-commercial', @channel.name) if resp.statusCode is 204

        @messages = []
        @lastTime = now

    say: (bot, msg) ->
        bot.say '[AutoCommercial] ' + msg

        
exports.New = (channel) -> new AutoCommercial channel
