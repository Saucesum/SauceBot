# SauceBot IRC Client

sio   = require 'socket.io-client'
color = require 'colors'

io    = require './ioutil'

[node, filename, channel, username, message] = process.argv

unless (message)
    io.error "usage: #{node} #{filename} <channel> <username> <message>"
    return


  
sauce = sio.connect 'http://localhost:8455'

setTimeout ->
    
    match = /^(?:!(\w+)\s*)?(.*)/.exec message
   
    sauce.emit 'msg'
        chan: channel
        user: username
        op  : 1
        cmd : match[1]
        args: match[2]
    
, 300
    
sauce.on 'say', (data) ->
    {chan, msg} = data
    
    unless chan?
        io.error "No such channel: #{chan}"
        return

    io.debug "#{chan}: #{msg}"
