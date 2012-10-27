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

exports.strings = {
    'config-enable'    : 'Enabled'
    'config-disable'   : 'Disabled'
    'action-commercial': 'Commercial! Disable ad-blockers to support @1@. <3'
    'action-delay'     : 'Minimum delay set to @1@ minutes.'
    'action-messages'  : 'Minimum number of messages set to @1@.'
}

io.module '[AutoCommercial] Init'

oauth = new TokenJar Sauce.API.Twitch, Sauce.API.TwitchToken


# Constants
MINIMUM_DELAY    = 15
MINIMUM_MESSAGES = 5

class AutoCommercial extends Module
    constructor: (@channel) ->
        super @channel
        @comDTO = new ConfigDTO @channel, 'autocommercial', ['state', 'delay', 'messages']
        
        @messages = []
        @lastTime = 0
        
        
    load: ->
        @registerHandlers()
        @comDTO.load()
        

    registerHandlers: ->
        # !commercial on - Enable auto-commercials
        @regCmd "commercial on", Sauce.Level.Admin,
            (user,args,bot) =>
                @cmdEnableCommercial()
                bot.say '[AutoCommercial] ' + @str('config-enable')
        
        # !commercial off - Disable auto-commercials
        @regCmd "commercial off", Sauce.Level.Admin,
            (user,args,bot) =>
                @cmdDisableCommercial()
                bot.say '[AutoCommercial] ' + @str('config-disable')

        # !commercial delay <minutes> - Set delay
        @regCmd "commercial delay", Sauce.Level.Admin,
            (user, args, bot) =>
                @cmdDelay user, args, bot

        # !commercial messages <minutes> - Set messages
        @regCmd "commercial messages", Sauce.Level.Admin,
            (user, args, bot) =>
                @cmdMessages user, args, bot
        
        @regVar "commercial", (user, args, cb) =>
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
                
    cmdEnableCommercial: ->
        @comDTO.add 'state', 1
        @lastTime = Date.now()
    
    
    cmdDisableCommercial: ->
        @comDTO.add 'state', 0


    cmdDelay: (user, args, bot) ->
        num = (parseInt args[0], 10) or 0
        num = MINIMUM_DELAY if num < MINIMUM_DELAY
        @comDTO.add 'delay', num
        bot.say "[AutoCommercial] " + @str('action-delay', num)


    cmdMessages: (user, args, bot) ->
        num = (parseInt args[0], 10) or 0
        num = MINIMUM_MESSAGES if num < MINIMUM_MESSAGES
        @comDTO.add 'messages', num
        bot.say "[AutoCommercial] " + @str('action-messages', num)
        

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
        
        oauth.get "/channels/#{@channel.name}/commercial", 'POST', (resp, body) =>
            # "204 No Content" if successful.
            bot.say @str('action-commercial', @channel.name) if resp.statusCode is 204

        @messages = []
        @lastTime = now

        
exports.New = (channel) -> new AutoCommercial channel
