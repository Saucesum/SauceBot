# SauceBot Module: AutoCommercial

Sauce = require '../sauce'
db    = require '../saucedb'
io    = require '../ioutil'

{ConfigDTO} = require '../dto' 

# Module description
exports.name        = 'AutoCommercial'
exports.version     = '1.0'
exports.description = 'Automatic commercials for jtv partners (Broken - do not use)'
exports.locked      = true
exports.ignore      = true

exports.strings = {
    'config-enable' : 'Enabled'
    'config-disable': 'Disabled'
}

io.module '[AutoCommercial] Init'

# ********************************************************************** #
#                                NOTE                                    #
# ---------------------------------------------------------------------- #
#  This module needs to be competely rethinked due to the fact that      #
#  only the broadcaster can use /commercial from the chat.               #
#                                                                        #  
#  Another way of starting a commercial is to use the JTV API            #
#  /broadcast/dashboards/<channel>/commercial?length=30                  #
#  However, that requires a JTV application key for the OAuth.           #
#                                                                        #
#  More information regarding the API:                                   #
#  http://apiwiki.justin.tv/mediawiki/index.php/Channel/commercial       #
#                                                                        #
# ********************************************************************** #
class AutoCommercial
    constructor: (@channel) ->
        @comDTO = new ConfigDTO @channel, 'autocommercial', ['state', 'delay', 'messages']
        
        @messages = []
        @lastTime = 0
        @loaded = false
        
        
    load: ->
        io.module "[AutoCommercial] Loading for #{@channel.id}: #{@channel.name}"
        
        @registerHandlers() unless @loaded
        
        @comDTO.load()
        
    unload: ->
        return unless @loaded
        @loaded = false
        
        io.module "[AutoCommercial] Unloading from #{@channel.id}: #{@channel.name}"
        myTriggers = @channel.listTriggers { module:this }
        @channel.unregister myTriggers...


    registerHandlers: ->
        # !commercial on - Enable auto-commercials
        @channel.register this, "commercial on"      , Sauce.Level.Mod,
            (user,args,bot) =>
                @cmdEnableCommercial()
                bot.say '[AutoCommercial] ' + @str('config-enable')
        
        # !commercial off - Disable auto-commercials
        @channel.register this, "commercial off"     , Sauce.Level.Mod,
            (user,args,bot) =>
                @cmdDisableCommercial()
                bot.say '[AutoCommercial] ' + @str('config-disable')
                
                
    cmdEnableCommercial: ->
        @comDTO.add 'state', 1
    
    
    cmdDisableCommercial: ->
        @comDTO.add 'state', 0
        

    updateMessagesList: (now) ->
        delay = @comDTO.get 'delay'
        delay = 30 if delay < 30
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
        msgsLimit = 30 if msgsLimit < 30
        
        delay = @comDTO.get 'delay'
        delay = 30 if delay < 30
        
        return unless @messagesSinceLast() >= msgsLimit and (now - @lastTime > (delay * 60 * 1000))
        
        bot.commercial()
        @messages = []
        @lastTime = now

        
exports.New = (channel) -> new AutoCommercial channel
