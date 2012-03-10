# SauceBot JTV Client

color      = require 'colors'
term       = require 'readline'
util       = require 'util'
fs         = require 'fs'

io         = require '../common/ioutil'
{Client}   = require '../common/socket'
{SauceIRC} = require './irc'

# Config
HOST = '127.0.0.1'
PORT = 8455

debug = true

# IRC channel
class Channel
    constructor: (@server, @username, password) ->
        @irc = new SauceIRC @server, username, password
        io.socket "Joining channel #{@server}..."
        @irc.connect()
        @irc.setDebug debug
        
        @users = []
        
        @irc.on 'message' + @irc.channel, (from, message) =>
            if /ravn|sauce/i.test message
                io.irc @irc.channel, from, message.green.inverse
            else
                io.irc @irc.channel, from, message
            
            sauce.emit 'msg',
                chan: @server
                user: from
                msg : message
                op  : if @isOp from then 1 else 0

                
        @irc.on 'error', (message) =>
            io.error message
            
            
        @irc.on 'motd', (motd) =>
            channels[@server] = @
            io.socket "Connected to #{@server}"
            
        @irc.on 'names', (channel, nicks) =>
            @addUser nick, tag for nick, tag of nicks

        @irc.on 'modeadd', (channel, source, mode, user, message) =>
            return unless mode is 'o'
            @addUser user, '@'
            
        @irc.on 'moderem', (channel, source, mode, user, message) =>
            return unless mode is 'o'
            @removeUser user

            
    addUser: (nick, tag) ->
        @users[nick] = tag
        
        
    removeUser: (nick) ->
        if nick.indexOf(0) in [' ', '+', '@'] then nick = nick.substring 1
        @users[nick] = null
        
        f
    isOp: (nick) ->
        return @users[nick] is '@' if @users[nick]?
        
        
    say: (message) ->
        @irc.say message
        
        
    sayRaw: (message) ->
        @irc.sayRaw message
        
        
    part: ->
        io.socket "Parting channel #{@server}..."
        @irc.disconnect()


    setDebug: (dbg) ->
        @irc.setDebug dbg

[_, _, botName, botPassword, chanfile] = process.argv

channels = {}
sauce = new Client HOST, PORT

if chanfile?
    fs.readFile chanfile, 'UTF-8', (err, data) ->
        if err
            io.error err
            process.exit(1)
        
        for line in data.split "\n"
            line = line.trim()
            continue unless line
            initChannel line

io.say "Welcome to SauceJTV!"

sauce.on 'say', (data) ->
    {chan, msg} = data
    channel = channels[chan]
    
    return unless channel?
        
    channel.say msg
    io.irc '#' + chan, channel.username, (msg + '').cyan
    
sauce.on 'error', (data) ->
    {msg} = data
    io.error msg
    
    
autocomplete = (line) ->
    if m = /^(say|part)\s+(.*)$/i.exec line
        txt = m[2]
        chanlist = Object.keys(channels).sort()
        chanlist = (m[1] + ' ' + chan + ' ' for chan in chanlist when chan.indexOf(txt) is 0)
        [chanlist, line]
    else
        opts = ['join ', 'part ', 'say ', 'list', 'debug']
        [(opt for opt in opts when opt.indexOf(line) is 0), line]


rl = term.createInterface process.stdin, process.stdout, autocomplete
rl.setPrompt "#{botName}> "
rl.prompt()

rl.on 'line', (line) ->
    try
        if m = /^join\s+([a-zA-Z0-9_]+)/i.exec line
            chan = m[1]
            initChannel chan
            return rl.prompt()
                    
        if m = /^part\s+([a-zA-Z0-9_]+)/i.exec line
            chan = m[1]
            removeChannel chan
            return rl.prompt()
            
        if m = /^say\s+([a-zA-Z0-9_]+)\s+(.+)$/i.exec line
            chan = m[1]
            msg  = m[2]
            sayChannel chan, msg
            return rl.prompt()
            
        if m = /^list\s*/i.exec line
            for name, chan of channels
                io.say chan.username.magenta + ':' + name.blue.bold + " [" + ((tag ? ' ') + name for name, tag of chan.users).join(', ') + "]"
            return rl.prompt()
            
        if m = /^debug\s+(on|off)/i.exec line
            if m[1] is 'on'
                debug = true
                chan.setDebug(true)  for name, chan of channels
                io.say 'Debugging ' + 'enabled'.green
            if m[1] is 'off'
                debug = false
                chan.setDebug(false) for name, chan of channels
                io.say 'Debugging ' + 'disabled'.red
            return rl.prompt()
            
    catch error
        io.error error
        
    io.say "Invalid command: #{line}"
    rl.prompt()
        
rl.on 'close', ->
    for name, chan of channels
        chan.part()
        
    console.log "\nStopping.\n"

        
initChannel = (chan) ->
    channel = new Channel(chan, botName, botPassword)

removeChannel = (chan) ->
    channel = channels[chan]
    if channel?
        channel.part()
        delete channels[chan]

sayChannel = (chan, msg) ->
    channel = channels[chan]
    if channel?
        channel.sayRaw msg
        io.irc '#' + chan, channel.username, msg.cyan
