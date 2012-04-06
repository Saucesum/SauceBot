color      = require 'colors'
term       = require 'readline'
util       = require 'util'
fs         = require 'fs'

io         = require '../common/ioutil'

class SauceTerm
    
    
    constructor: (@getChannels, @getBots) ->
        @handlers = {}
        @rl = term.createInterface process.stdin, process.stdout, (line) =>
            @autocomplete line
            
        @setPrompt undefined
        @prompt()
        
        @rl.on 'line', (line) =>
            if m = /^join\s([a-zA-Z0-9_]+)/i.exec line
                chan = m[1]
                @emit 'join', chan
                return @prompt()
                
            if m = /^part\s+([a-zA-Z0-9_]+)/i.exec line
                chan = m[1]
                @emit 'part', chan
                return @prompt()
            
            if m = /^say\s+([a-zA-Z0-9_]+)\s+(.+)$/i.exec line
                chan = m[1]
                msg  = m[2]
                @emit 'say', chan, msg
                return @prompt()
                
            if m = /^list/i.exec line
                @emit 'list'
                return @prompt()
                
            if m = /^set\s+([a-zA-Z0-9_]+)/i.exec line
                name = m[1]
                @emit 'set', name
                @setPrompt name if @isBot name
                return @prompt()
                
            if m = /^close/i.exec line
                @emit 'close'
                
        @rl.on 'close', =>
            @emit 'close'
                
        
        
    setPrompt: (name) ->
        @name = if name? then @getRealName(name) else @getFirstBot()
        
        @rl.setPrompt @name + '> '
        
        
    getRealName: (name) ->
        for bot in @getBots()
            return bot if bot.toLowerCase() is name.toLowerCase()
        name
        
    
    isBot: (name) ->
        name.toLowerCase() in (bot.toLowerCase() for bot in @getBots())
        
        
    getFirstBot: ->
        @getBots()[0]


    prompt: ->
        @rl.prompt()

    
    autocomplete: (line) ->
        if m = /^(say|part)\s+(.*)$/i.exec line
            cmd = m[1]
            txt = m[2].toLowerCase()
            chanlist = @getChannels().sort()
            chanlist = (m[1] + ' ' + chan + ' ' for chan in chanlist when chan.toLowerCase().indexOf(txt) is 0)
            [chanlist, line]
            
        else if m = /^set\s+(.*)$/i.exec line
            txt = m[1].toLowerCase()
            botlist = @getBots().sort()
            botlist = ('set ' + bot for bot in botlist when bot.toLowerCase().indexOf(txt) is 0)
            [botlist, line]
            
        else
            opts = ['join ', 'part ', 'say ', 'list', 'set ', 'close']
            [(opt for opt in opts when opt.indexOf(line) is 0), line]


    on: (cmd, handler) ->
        @handlers[cmd] = handler


    emit: (cmd, args...) ->
        if handler = @handlers[cmd]
            handler(@name, args...)



exports.SauceTerm = SauceTerm