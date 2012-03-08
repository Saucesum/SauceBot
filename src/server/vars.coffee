# SauceBot Command Variable Handler

# Commands:
#
# botname - Name of the bot
#    - botname -> SauceBot
# botversion - Version of the current bot
#   - botversion -> 2.7
#
# name - Name of the command-source
#   - name -> ravn_tm
# channel - Channel name
#   - channel -> CilantroGamer
#
# rand(val1, [val2, [val3, [...]]]) - Random number generator
#  - rand(5) -> 4
#  - rand(10, 15) -> 12
#  - rand(a, b, c, d, e) -> d
#
# time(timezone) - Current time
#   - timezone('GMT') -> 13:15:22
# countdown(timezone, ...) - Counts down to something
#
#
# Examples:
#
# !greetme : Hello, there, ${name}! Welcome to ${channel}!
# !now     : The current time for ${channel} is ${time US/Eastern}
# !dir     : You should go... ${rand Left, Right, Up, Down}!
# !bot     : [Bot] Running ${botname} version ${botversion}
#


time       = require 'time'
color      = require 'colors'
os         = require 'os'

Sauce      = require './sauce'

varRE = /\$\((\w+)(?:\s+([^)]+))?\)/

pad = (num) ->
    if num < 10 then "0" + num else num

formatTime = (date) ->
    hours = pad date.getHours()
    mins  = pad date.getMinutes()
    secs  = pad date.getSeconds()
    
    "#{hours}:#{mins}:#{secs}"
        
       
# MineCraft chat colours
colors =
        BLACK       : '§0'
        DARK_BLUE   : '§1'
        DARK_GREEN  : '§2'
        DARK_AQUA   : '§3'
        DARK_RED    : '§4'
        DARK_PURPLE : '§5'
        GOLD        : '§6'
        GRAY        : '§7'
        DARK_GRAY   : '§8'
        BLUE        : '§9'
        GREEN       : '§a'
        AQUA        : '§b'
        RED         : '§c'
        LIGHT_PURPLE: '§d'
        YELLOW      : '§e'
        WHITE       : '§f'
        MAGIC       : '§k'
        
class Vars
    constructor: (@channel) ->
        
        @handlers =
            botname   : (user, args) -> Sauce.Name
            botversion: (user, args) -> Sauce.Version
            
            name      : (user, args) -> user.name
            channel   : (user, args) => @channel.name
            
            col       : (user, args) -> if args? and args[0]? then colors[args[0].toUpperCase()] else colors['WHITE']
        
            rand      : (user, args) ->
                return 0 unless args
                
                switch args.length
                        when 1
                            a = parseInt(args[0], 10)
                            Math.floor(Math.random() * a)
                        when 2
                            a = parseInt(args[0], 10)
                            b = parseInt(args[1], 10)
                            Math.floor(Math.random() * (b - a)) + a
                        else
                            idx = Math.floor(Math.random() * args.length)
                            args[idx]
                        
            
            time      : (user, args) ->
                now = new time.Date()
                try
                    now.setTimezone args[0]
                catch error
                    
                formatTime now
                    
                    
    register: (cmd, handler) ->
        @handlers[cmd] = handler
        
        
    unregister: (cmd, handler) ->
        delete @handlers[cmd]
    
                    
    parse: (user, message) ->
        @matchVars message, (m, cmd, args) =>
            result = @handle user, cmd, args
            
            idx = m.index
            len = m[0].length
            
            pre  = message.substring 0, idx
            post = message.substring idx + len
            
            message = pre + result + post
        
        message
            

    matchVars: (message, cb) ->
        return unless '$' in message
        
        while m = varRE.exec message
            cmd  = m[1]
            args = if m[2] then m[2].split ',' else [] 
            message = cb m, cmd, args
            

    handle: (user, cmd, args) ->
        return cmd unless handler = @handlers[cmd]
        handler user, args



exports.Vars = Vars
exports.formatTime = formatTime
