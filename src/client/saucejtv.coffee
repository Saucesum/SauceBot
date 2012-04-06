
# Node.js
color      = require 'colors'
term       = require 'readline'
util       = require 'util'
fs         = require 'fs'

# SauceBot
io         = require '../common/ioutil'
config     = require '../common/config'
{Client}   = require '../common/socket'
{Term}     = require '../common/term'
{Channel}  = require './saucechan'

# CONFIG
{server, highlight, accounts} = config.load 'jtv'

HOST = server.host
PORT = server.port

HIGHLIGHT = new RegExp highlight.join('|'), 'i'

sauce = new Client HOST, PORT

sauce.on 'say', (data) ->
    {chan, msg} = data
    bot.say chan, msg for _, bot of bots


sauce.on 'error', (data) ->
    io.error data.msg
    

class Bot
    constructor: (@name, @password) ->
        @channels = {}
        
    get: (name) ->
        @channels[name.toLowerCase()]
        
    add: (name) ->
        @remove name
        lc = name.toLowerCase()
        
        chan = new Channel name, @name, @password
        @channels[lc] = chan
       
        chan.on 'message', (args) =>
            {from, message, op} = args
            
            prefix = if op then '@' else ' '
           
            if HIGHLIGHT.test message
                io.irc name, prefix + from, message.green.inverse
            else
                io.irc name, prefix + from, message
               
            sauce.emit 'msg',
                chan: name.toLowerCase()
                user: from
                msg : message
                op  : op
               
           
        chan.on 'error', (msg) =>
            io.error msg
           
        chan.on 'connected', =>
            io.socket "Connected to #{@name}/#{name.bold}"
           
        chan.on 'disconnecting', =>
            io.socket "Disconnecting from #{@name}/#{name.bold}"
           
        chan.on 'connecting', =>
            io.debug "Connecting to #{@name}/#{name.bold}..."
           
           
        chan.connect()
       
    remove: (name) ->
        lc = name.toLowerCase()
        chan = @channels[lc]
        if chan?
            chan.part()
            delete @channels[lc]
            
    list: ->
        #io.debug @name + ": " + @channels
        (name for name, _ of @channels)
        
    say: (chan, msg) ->
        channel.say msg if (channel = @get chan)?
        
    sayRaw: (chan, msg) ->
        channel.sayRaw msg if (channel = @get chan)?
        

bots = {}
currentBot = 'SauceBot'

for account in accounts
    botName = account.username
    bot = new Bot botName, account.password
    
    bot.add chan for chan in account.channels
    
    bots[botName.toLowerCase()] = bot
    

termPart = (name, chan) ->
    bots[name.toLowerCase()].remove chan
        
        
termJoin = (name, chan) ->
    bots[name.toLowerCase()].add chan
    
    
termSay = (name, chan, msg) ->
    bots[name.toLowerCase()].sayRaw chan, msg
    
termUse = (bot) ->
    io.debug "Switched to #{bot.bold}"
    
termList = ->
    for name, bot of bots
        console.log " #{name.underline.bold.blue}"
        console.log "\t" + (chan.magenta for chan in bot.list()).join(', ')
        
termClose = ->
    for _, {channels} of bots
        chan.part() for __, chan of channels
            
    setTimeout ->
        process.exit()
    , 2000

        
chanList = -> bots[currentBot.toLowerCase()].list()
botList  = -> Object.keys bots 
        

# SauceBot terminal handler
term = new Term currentBot


term.on 'part', [chanList], (chan) ->
    termPart currentBot, chan
   
term.on 'join', [true], (chan) ->
    termJoin currentBot, chan

term.on 'say', [chanList, true], (chan, msg) ->
    termSay currentBot, chan, msg
    
term.on 'list', [], ->
    termList()
    
term.on 'use', [botList], (bot) ->
    termUse bot
    currentBot = bot
    term.setPrompt currentBot
    
term.on 'close', [], ->
    termClose()

