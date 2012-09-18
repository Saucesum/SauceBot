# SauceBot Twitch Client

# Node.js
color      = require 'colors'
term       = require 'readline'
util       = require 'util'
fs         = require 'fs'

# SauceBot
io         = require '../common/ioutil'
config     = require '../common/config'
log        = require '../common/logger'
{Client}   = require '../common/socket'
{Term}     = require '../common/term'
{Twitch}   = require './twitch'

{server, highlight, accounts, logging} = config.load 'jtv'

HOST = server.host
PORT = server.port

HIGHLIGHT = new RegExp highlight.join('|'), 'i'

logger = new log.Logger logging.root, "client.log"

sauce = new Client HOST, PORT

twitch = new Twitch

for password, username in accounts
    twitch.addAccount username, password

# Add handlers for messages from Twitch

twitch.on 'message', (chan, from, op, message) ->
    prefix = if op then '@' else ' '
   
    if HIGHLIGHT.test message
        io.irc chan, prefix + from, message.green.inverse
    else
        io.irc chan, prefix + from, message
       
    sauce.emit 'msg',
        chan: chan.toLowerCase
        user: from
        msg : message
        op  : op

twitch.on 'pm', (from, message) ->
    io.irc 'PM', from, message
    pmlog.timestamp from, message
    
    sauce.emit 'pm',
        user: from
        msg : message

twitch.on 'error', (chan, message) ->
    io.error "Error in channel #{chan}: #{message}"

twitch.on 'connected', (chan) ->
    io.socket "Connected to #{@chan}"

twitch.on 'connecting', (chan) ->
    io.socket "Connecting to #{@chan}"

twitch.on 'disconnecting', (chan) ->
    io.socket "Disconnecting from #{@chan}"

# Add handlers for messages from SauceBot

sauce.on 'say', (data) ->
    {chan, msg} = data
    twitch.say chan, msg, logger

sauce.on 'ban', (data) ->
    {chan, user} = data
    console.log "/ban #{user}"
    twitch.sayRaw chan, "/ban #{user}", logger

sauce.on 'unban', (data) ->
    {chan, user} = data
    console.log "/unban #{user}"
    twitch.sayRaw chan, "/unban #{user}", logger

sauce.on 'timeout', (data) ->
    {chan, user, time} = data
    time ?= 600
    console.log "/timeout #{user} #{time}"
    twitch.sayRaw chan, "/timeout #{user} #{time}", logger

sauce.on 'commercial', (data) ->
    {chan} = data
    twitch.say chan, "Commercial incoming! Please disable ad-blockers if you want to support #{chan}. <3"
    twitch.sayRaw chan, '/commercial', logger

sauce.on 'channels', (channels) ->
    # I suppose this is unnecessary
    # twitch.part chan.name, chan.bot for chan in channels when "#{chan.name.toLowerCase()}::#{chan.bot.toLowerCase()}" in twitch.getChannels and not chan.status
    # twitch.join chan.name, chan.bot for chan in channels when not "#{chan.name.toLowerCase()}::#{chan.bot.toLowerCase()}" in twitch.getChannels and chan.status
    
    # Twitch checks whether channels are connected for us already, so we
    # probably don't need to check on our own
    twitch.part chan.name, chan.bot for chan in channels when not chan.status
    twitch.join chan.name, chan.bot for chan in channels when chan.status
 
sauce.on 'error', (data) ->
    io.error data.msg

# Terminal stuff

currentBot = 'SauceBot'

term = new Term currentBot

term.on 'part', [twitch.getShortChannels], (chan) ->
    twitch.part chan, currentBot
   
term.on 'join', [true], (chan) ->
    twitch.join chan, currentBot

term.on 'say', [twitch.getShortChannels, true], (chan, msg) ->
    twitch.sayRaw chan, msg, logger
    
term.on 'list', [], ->
    console.log ("#{bot.underline.bold.blue}: #{chan.magenta}" for channel in twitch.getChannels() when [bot, chan] = channel.split("::")).join '\n'
    
term.on 'use', [twitch.getAccounts], (bot) ->
    io.debug "Switched to #{bot.bold}"
    currentBot = bot
    term.setPrompt currentBot
    
term.on 'close', [], ->
    twitch.close()
    setTimeout ->
        process.exit()
    , 5000

# Start it all up    

sauce.emit 'get',
    cookie : 'OMNOMNOM',
    chan   : '4',
    type   : 'Channels'
