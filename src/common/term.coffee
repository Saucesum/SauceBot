require 'colors'

class Term
    constructor: (prompt) ->
        @commands = {}
        
        @rl = require('readline').createInterface process.stdin, process.stdout, (line) =>
            @autocomplete line
            
        @rl.on 'line', (line) =>
            @handle line
            
        @rl.on 'close', =>
            @commands['close'].cb()
        
        @setPrompt prompt

        
    setPrompt: (@prompt) ->
        @rl.setPrompt @prompt + '> '
        @rl.prompt()


    on: (cmd, def, cb) ->
        @commands[cmd] =
            def: def
            cb : cb

    
    autocomplete = (line) ->
        lc = line.toLowerCase()
        opts = []
        for name, {def} of commands
            opts.push name if name.indexOf(lc) is 0
            continue unless lc.indexOf(name) is 0
            
            txt = line.substring name.length + 1
            
            if def[0]? and typeof def[0] is 'function'
                list = def[0]().sort()
                list = (name + ' ' + elem for elem in list when elem.toLowerCase().indexOf(txt) is 0)
                return [list, line]
                
        [opts, line]
        
            
    handle: (line) ->
        [name, args...] = (line = line.trim()).split /\s+/
        
        cmd = @commands[name]
        if cmd?
            args = @parseArgs cmd.def, args
            cmd.cb.apply null, args
            
        else if name
            console.log "< Unknown command #{name.bold}. Commands: #{(name.bold for name, _ of @commands).join ' '} >".red.inverse     
        
        return @rl.prompt()
    
    
    parseArgs: (def, args) ->
        (if argdef is true then args.join ' ' else @getListElem argdef(), args.shift()) for argdef in def
        
    
    getListElem: (list, val) ->
        ([value] = (elem for elem in list when elem.toLowerCase() is val.toLowerCase()))[0] ? val
    
    
    autocomplete: (line) ->
            lc = (line = line.trim()).toLowerCase()
            opts = []
            for name, {def} of @commands
                opts.push name + ' ' if name.indexOf(lc) is 0
                continue unless lc.indexOf(name) is 0
    
                
                txt = line.substring name.length + 1
                
                if def[0]? and typeof def[0] is 'function'
                    list = def[0]().sort()
                    list = (name + ' ' + elem + ' ' for elem in list when elem.toLowerCase().indexOf(txt) is 0)
                    return [list, line]
                    
            [opts, line]
                                
                    
exports.Term = Term