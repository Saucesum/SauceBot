io         = require '../common/ioutil'
config     = require '../common/config'
{SauceIRC} = require './irc'

class Channel
    
    constructor: (@name, @username, @password) ->
        @handlers = {}
        @users    = {}
        @server   = @name
        @irc = new SauceIRC @server, @username, @password
        
        @irc.on 'message' + @irc.channel, (from, message) =>
            @emit 'message',
                from    : from
                message : message
                op      : if @isOp from then 1 else null
                
        @irc.on 'pm', (from, message) =>
            @emit 'pm',
                from    : from
                message : message
                
        @irc.on 'error', (message) =>
            @emit 'error', message
            
        @irc.on 'motd' , (motd) =>
            @irc.send 'JTVROOMS', @irc.channel
            @irc.send 'JTVCLIENT', @irc.channel
            setTimeout =>
                @irc.send 'WHO', @irc.channel
            , 3000

            @emit 'connected'
            
        @irc.on 'names', (channel, nicks) =>
            @addUser nick, tag for nick, tag of nicks
            
        @irc.on 'modeadd', (channel, source, mode, user, message) =>
            return unless mode is 'o'
            @addUser user, '@'
            
        @irc.on 'moderem', (channel, source, mode, user, message) =>
            return unless mode is 'o'
            @removeUser user
                
                
    addUser: (nick, tag) ->
        @users[nick] = tag
        
        
    removeUser: (nick) ->
        if nick.indexOf(0) in [' ', '+', '@'] then nick = nick.substring 1
        @users[nick] = null
                
                
    isOp: (nick) ->
        return @users[nick] is '@' if @users[nick]?
        
        
    say: (message) ->
        @irc.say message
        
    
    sayRaw: (message) ->
        @irc.sayRaw message
        
        
    part: ->
        @emit 'disconnecting'
        @irc.disconnect()
        
        
    connect: ->
        @emit 'connecting'
        @irc.connect()
    
    
    on: (cmd, handler) ->
        @handlers[cmd] = handler


    emit: (cmd, args) ->
        if fn = @handlers[cmd]
            fn args

exports.Channel = Channel
