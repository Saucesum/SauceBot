# SauceBot Module: AutoCommercial

Sauce = require '../sauce'
db    = require '../saucedb'
io    = require '../ioutil'

{ConfigDTO} = require '../dto' 

# Module description
exports.name        = 'AutoCommercial'
exports.version     = '1.0'
exports.description = 'Automatic commercials for jtv partners'

io.module '[AutoCommercial] Init'

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
        @channel.register this, "commercial on"      , Sauce.Level.Admin,
            (user,args,bot) =>
                @cmdEnableCommercial()
                bot.say '[AutoCommercial] Enabled'
        
        # !commercial off - Disable auto-commercials
        @channel.register this, "commercial off"     , Sauce.Level.Admin,
            (user,args,bot) =>
                @cmdDisableCommercial()
                bot.say '[AutoCommercial] Disabled'
                
                
    cmdEnableCommercial: ->
        @comDTO.set 'state', 1
    
    
    cmdDisableCommercial: ->
        @comDTO.set 'state', 0
        

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
