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

varRE = /\$\{(\w+)(?:\s+([^}]+))?\}/

pad = (num) ->
    if num < 10 then "0" + num else num

formatTime = (date) ->
    hours = pad date.getHours()
    mins  = pad date.getMinutes()
    secs  = pad date.getSeconds()
    
    "#{hours}:#{mins}:#{secs}"
        

handlers =
    botname   : (channel, user, args) -> 'SauceBot' # TODO
    botversion: (channel, user, args) -> '3.1'      # TODO
    
    name      : (channel, user, args) -> user.username
    channel   : (channel, user, args) -> channel.name
    
    rand      : (channel, user, args) ->
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
                
    
    time      : (channel, user, args) ->
        now = new time.Date()
        try
            now.setTimezone args[0]
        catch error
            # ...
            
        formatTime now
        
    countdown : (channel, user, args) ->
        format = dateFormat.masks.isoTime
        now = new time.Date()
        
        try
            now.setTimezone(args[0])
            
            # TODO: Do the actual count down thingy.
            
        catch error
            # ...
        


matchVars = (message, cb) ->
    return unless '{' in message
    
    while m = varRE.exec message
        
        cmd  = m[1]
        args = m[2].split ',' if m[2]?
        message = cb m, cmd, args
    

parse = (channel, user, message) ->
    matchVars message, (m, cmd, args) ->
        result = handle channel, user, cmd, args
        
        idx = m.index
        len = m[0].length
        
        pre  = message.substring(0, idx)
        post = message.substring(idx + len)
        
        message = pre + result + post
        
    message
    
handle = (channel, user, cmd, args) ->
    return cmd unless handler = handlers[cmd]
    handler channel, user, args
    
exports.parse = parse
exports.formatTime = formatTime
