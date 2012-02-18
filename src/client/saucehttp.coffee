# SauceBot HTTP "Client"

require.paths.push '../../common/bin'

sio   = require 'socket.io-client'
url   = require 'url'
http  = require 'http'
color = require 'colors'

io    = require 'ioutil'
auth  = require 'session'

# Program arguments start at index 2
[_, _, port] = process.argv

# Default port is 8080
port ?= 8080


sauce = sio.connect 'http://localhost:8455'
  
server = http.createServer (req, res) ->
    res.writeHead 200,
        'Content-Type': 'application/json; charset=utf-8'

    {cookie, chan, user, message} = res
    
    match = /^(?:!(\w+)\s*)?(.*)/.exec message
    
    op = null
    if user[0] is '@'
        user = user.substring 1
        op = 1
    
    sauce.emit 'msg',
        chan: chan
        user: user
        op  : op
        cmd : match[1]
        args: match[2]
        
    io.debug "#{chan}: <#{user}> (#{match[1] or ''}) #{match[2]}"
        
    
    
sauce.on 'say', (data) ->
    {chan, msg} = data
    
    channel = channels[chan]
    
    unless chan?
        io.error "No such channel: #{chan}"
        return

    channel.say msg
