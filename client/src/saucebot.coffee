# SauceBot IRC Client

sio   = require 'socket.io-client'
color = require 'colors'

io    = require './ioutil'
irc   = require './sauceirc'

[node, filename, channelnames, username, password] = process.argv

unless (password)
    io.error "usage: #{node} #{filename} <channel1:channel2:...:channelN> <username> <password>"
    return


  
sauce = sio.connect 'http://localhost:8455'

# Channel list: name -> obj[SauceIRC]
channels = {}


for channelname in channelnames.split ':'
    io.say "Connecting to #{channelname.magenta}..."

    channel = irc.setup channelname, username, password,
            (message) ->
                # onError:
                {command, args} = message
            
                io.error "#{command}: #{args.join ' '}"
                
            , (from, message) ->
                # onMessage:
                
                match = /^(?:!(\w+)\s*)?(.*)/.exec message
                
                sauce.emit 'msg',
                    chan: channelname
                    user: from
                    op  : 1
                    cmd : match[1]
                    args: match[2]
                
                io.debug "#{channelname}: <#{from}> (#{match[1]}) #{match[2]}"

#sauce.emit 'msg',
#        chan: 'ravn_tm'
#        user: 'ravn_tm'
#        cmd : 'vm'
#        args: ''

