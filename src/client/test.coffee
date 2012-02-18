# SauceBot IRC Client

sio   = require 'socket.io-client'
color = require 'colors'

io    = require './ioutil'
irc   = require './sauceirc'

[node, filename, cookie, channel, type] = process.argv


sauce = sio.connect 'http://localhost:8455'

sauce.emit 'upd',
    cookie: cookie
    chan  : channel
    type  : type
    

    
sauce.on 'error', (data) ->
    {msg} = data

    io.error msg
