# SauceBot IRC Client

sio   = require 'socket.io-client'
color = require 'colors'

io    = require './ioutil'
irc   = require './sauceirc'

[node, filename, channelnames, username, password] = process.argv

unless (password)
    io.error "usage: #{node} #{filename} <channel1:channel2:...:channelN> <username> <password>"
    return


  
sauce = sio.connect 'localhost:8455'

# Channel list: name -> obj[SauceIRC]
channels = {}


for channelname in channelnames.split ':'
    io.say "Connecting to #{channelname.magenta}..."

    channel = irc.setup channelname, username, password

    channels[channelname] = channel