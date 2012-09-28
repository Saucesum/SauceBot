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

logger = new log.Logger logging.root, "jtv.log"
pmlog  = new log.Logger logging.root, "pm.log"

# Connection to the SauceBot server
sauce = new Client HOST, PORT

# Connection manager for Twitch chats
twitch = new Twitch logger

# Register all bot accounts for use
for username, password of accounts
    io.debug "Account: " + username.bold
    twitch.addAccount username, password

# Add handlers for messages from Twitch

twitch.on 'message', (chan, from, op, message) ->
    prefix = if op then '@' else ' '
   
    if HIGHLIGHT.test message
        io.irc chan, prefix + from, message.green.inverse
    else
        io.irc chan, prefix + from, message
       
    sauce.emit 'msg',
        chan: chan.toLowerCase()
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
    io.socket "Connected to #{chan}"

twitch.on 'connecting', (chan) ->
    io.socket "Connecting to #{chan}"

twitch.on 'disconnecting', (chan) ->
    io.socket "Disconnecting from #{chan}"

# Add handlers for messages from SauceBot

sauce.on 'say', (data) ->
    {chan, msg} = data
    twitch.say chan, msg

sauce.on 'ban', (data) ->
    {chan, user} = data
    twitch.sayRaw chan, "/ban #{user}"

sauce.on 'unban', (data) ->
    {chan, user} = data
    twitch.sayRaw chan, "/unban #{user}"

sauce.on 'timeout', (data) ->
    {chan, user, time} = data
    time ?= 600
    twitch.sayRaw chan, "/timeout #{user} #{time}"

sauce.on 'commercial', (data) ->
    {chan} = data
    twitch.say chan, "Commercial incoming! Please disable ad-blockers if you want to support #{chan}. <3"
    twitch.sayRaw chan, '/commercial'

sauce.on 'channels', (channels) ->
    twitch.part chan.name, (chan.bot ? 'SauceBot') for chan in channels when not chan.status
    twitch.join chan.name, (chan.bot ? 'SauceBot') for chan in channels when chan.status
 
sauce.on 'error', (data) ->
    io.error data.msg

sauce.on 'connect', ->
    sauce.emit 'get', { type: 'Channels' }

# Terminal stuff

currentBot = 'SauceBot'

term = new Term currentBot

sayFunc = -> twitch.getShortChannels()
useFunc = -> twitch.getAccounts()

term.on 'say', [sayFunc, true], (chan, msg) ->
    twitch.sayRaw chan, msg, logger
    
term.on 'list', [], ->
    console.log "Channel list:\n\t".bold.blue + twitch.getShortChannels().join(", ")
    
term.on 'use', [useFunc], (bot) ->
    io.debug "Switched to #{bot.bold}"
    currentBot = bot
    term.setPrompt currentBot
    
term.on 'close', [], ->
    twitch.close()
    setTimeout ->
        process.exit()
    , 5000


# Register with the server as a chat client by requesting a channel list
#sauce.emit 'get', { type: 'Channels' }
