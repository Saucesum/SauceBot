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
twitchtv   = require './twitch'
{Client}   = require '../common/socket'
{Term}     = require '../common/term'

{server, highlight, accounts, logging} = config.load 'jtv.json'

HOST = server.host
PORT = server.port

HIGHLIGHT = new RegExp highlight.join('|'), 'i'

io.setLevel io.Level.All

logger = new log.Logger logging.root, "jtv.log"
pmlog  = new log.Logger logging.root, "pm.log"

# Connection to the SauceBot server
sauce = new Client HOST, PORT

{Twitch, toNodeColor} = twitchtv

# Connection manager for Twitch chats
twitch = new Twitch logger

userColors = {}

# Register all bot accounts for use
loadAccounts = (accounts) ->
    for username, password of accounts
        io.debug "Account: " + username.bold
        twitch.addAccount username, password

reloadAccountConfig = ->
    {accounts} = config.load 'jtv.json'
    loadAccounts accounts

loadAccounts accounts

# Add handlers for messages from Twitch

twitch.on 'message', (chan, from, op, message) ->
    prefix = if op then '@' else ' '

    col = toNodeColor userColors[from]
   
    if HIGHLIGHT.test message
        io.irc chan, prefix + from, message.green.inverse, col
    else
        io.irc chan, prefix + from, message, col
       
    sauce.emit 'msg',
        chan: chan.toLowerCase()
        user: from
        msg : message
        op  : op


parseUserColor = (msg) ->
    [_, name, col] = msg.split ' '
    userColors[name.toLowerCase()] = col


twitch.on 'pm', (srcchan, from, message) ->
    if /USERCOLOR/.test message
       parseUserColor message
    else if not /SPECIALUSER|EMOTESET/.test message
        io.irc 'PM', srcchan + '/' + from, message

    pmlog.timestamp from, message
    
    sauce.emit 'pm',
        chan: srcchan
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

sauce.on 'channels', (channels) ->
    reloadAccountConfig()

    for chan in channels when not chan.status
        twitch.part chan.name
    i = 0
    for chan in channels when chan.status
        do (chan) ->
            setTimeout ->
                twitch.join chan.name, (chan.bot ? 'SauceBot')
            , (i++) * 250

sauce.on 'rejoin', (channel) ->
    twitch.rejoin channel

sauce.on 'restart', (channel) ->
    reloadAccountConfig()
    twitch.restart()

sauce.on 'activity', ->
    last = {}
    for name, chan in twitch.connections
        last[name] = chan.lastActive
    sauce.emit 'activity', last

 
sauce.on 'error', (data) ->
    io.error data.msg

sauce.on 'connect', ->
    # Register as a chat client
    sauce.emit 'register', {
        type: 'chat'
        name: 'SauceClient'
    }

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
