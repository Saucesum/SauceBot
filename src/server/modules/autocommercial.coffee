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
exports.version     = '1.2'
exports.description = 'Automatic commercials for twitch.tv partners'
exports.ignore      = true

exports.strings = {
    'config-enable'    : 'Enabled'
    'config-disable'   : 'Disabled'

    'action-preparing' : 'Commercial coming in @1@ seconds!'
    'action-commercial': 'Commercial! Thank you for supporting @1@! <3'
    'action-canceled'  : 'Commercial canceled.'
    'action-failed'    : 'Could not run a commercial. Please contact SauceBot support.'
    'action-delay'     : 'Minimum delay set to @1@ minutes.'
    'action-messages'  : 'Minimum number of messages set to @1@.'
    'action-length'    : 'Commercial length set to @1@ seconds.'

    'info-editor'      : 'Note: This will only work if you\'ve set SauceBot as an editor.'
    'error-cancel'     : 'No commercial to cancel. You may only cancel ads @1@ seconds before they run.'
    'error-length'     : 'Error. Supported durations: @1@'
}

io.module '[AutoCommercial] Init'

oauth = new TokenJar Sauce.API.Twitch, Sauce.API.TwitchToken


# Constants
MINIMUM_DELAY    = 15
MINIMUM_MESSAGES = 15

COMMERCIAL_DELAY = 10 * 60 * 1000
COMMERCIAL_CANCEL_TIME = 15

DURATIONS = [30, 60, 90]

class AutoCommercial extends Module
    constructor: (@channel) ->
        super @channel
        @comDTO = new ConfigDTO @channel, 'autocommercial', ['state', 'delay', 'messages', 'length']
        
        @messages = []
        @lastTime = Date.now()
        @cancelNext = null

        
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

        # !commercial length <seconds> - Sets commercial length
        @regCmd "commercial length", Sauce.Level.Admin, @cmdLength

        # !cancelad - Cancels the next commercial
        @regCmd "cancelad", Sauce.Level.Mod, @cmdCancel

        # !commercial <time> - Runs a commercial
        @regCmd "commercial", Sauce.Level.Admin, @cmdCommercial
        
        # Variables $(commercial state|delay|messages)
        @regVar "commercial", @varCommercial

        # Register interface actions
        @regActs {
            'config': @actConfig
            'cancel': @actCancel
        }


    # Action handler for "config"
    # AutoCommercial.config([state|delay|messages|duration]*)
    actConfig: (user, params, res) =>
        {state, delay, messages, duration} = params

        unless state? or delay? or messages? or duration?
            return res.send @comDTO.get()

        unless user.isMod @channel.id, Sauce.Level.Admin
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

        # Commercial duration - any number in DURATIONS
        if duration?.length
            length = parseInt(duration, 10)
            @comDTO.add 'length', length if length in DURATIONS

        res.send @comDTO.get()


    # Action handler for "cancel" to stop the next commercial.
    # AutoCommercial.cancel()
    actCancel: (user, params, res) =>
        @cancelNext = true if @cancelNext isnt null
        res.ok()


    cmdEnableCommercial: (user, args)  =>
        @comDTO.add 'state', 1
        @lastTime = Date.now()
        @say @str('config-enable') + '. ' + @str('info-editor')
    
    
    cmdDisableCommercial: (user, args) =>
        @comDTO.add 'state', 0
        @say @str('config-disable')


    cmdDelay: (user, args) =>
        num = @clampMinimums 'delay', args[0]
        @say @str('action-delay', num)


    cmdMessages: (user, args) =>
        num = @clampMinimums 'messages', args[0]
        @say @str('action-messages', num)


    cmdLength: (user, args) =>
        num = parseInt(args[0], 10)
        if not (num in DURATIONS)
            @say @str('error-length', DURATIONS.join(', '))
        else
            @comDTO.add 'length', num
            @say @str('action-length', num)



    cmdCancel: (user, args) =>
        if @cancelNext is null
            return bot.say @str('error-cancel', COMMERCIAL_CANCEL_TIME)

        @cancelNext = true
        bot.say @str('action-canceled')


    cmdCommercial: (user, args) =>
        if @lastTime < COMMERCIAL_DELAY then return
        duration = parseInt(args[0], 10)
        duration = DURATIONS[0] unless duration in DURATIONS

        @lastTime = Date.now()

        oauth.post "/channels/#{@channel.name}/commercial", { length: duration }, (resp, body) =>
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
            when 'length'
                @comDTO.get 'length'
            else
                '$(commercial state|messages|delay|length)'
             

    updateMessagesList: (now) ->
        delay = @comDTO.get 'delay'
        delay = MINIMUM_DELAY if delay < MINIMUM_DELAY
        limit = now - (delay * 60 * 1000)
        
        @messages.push now
        @messages = (message for message in @messages when message > limit)
        
        
    messagesSinceLast: ->
        @messages.length


    handle: (user, msg) ->
        return unless @comDTO.get 'state'
        now = Date.now()
        
        @updateMessagesList now
        msgsLimit = @comDTO.get 'messages'
        msgsLimit = MINIMUM_MESSAGES if msgsLimit < MINIMUM_MESSAGES
        
        delay = @comDTO.get 'delay'
        delay = MINIMUM_DELAY if delay < MINIMUM_DELAY
        
        return unless @messagesSinceLast() >= msgsLimit and (now - @lastTime > (delay * 60 * 1000))

        bot.say @str('action-preparing', COMMERCIAL_CANCEL_TIME)
        
        setTimeout =>
            return if @cancelNext
            @cancelNext = null

            length = parseInt (@comDTO.get('length') ? DURATIONS[0]), 10

            oauth.post "/channels/#{@channel.name}/commercial", { length: length }, (resp, body) =>
                # "204 No Content" if successful.
                if resp.statusCode is 204
                    bot.say @str('action-commercial', @channel.name)
                else
                    bot.say @str('action-failed')

        , COMMERCIAL_CANCEL_TIME * 1000

        @messages = []
        @lastTime = now
        @cancelNext = false

        
exports.New = (channel) -> new AutoCommercial channel
