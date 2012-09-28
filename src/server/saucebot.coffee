 ###########################################################
#                                                           #
# - Node.js implementation of the SauceBot Command Server - #
#                                                           #
 ###########################################################
 
# Config
Sauce = require './sauce'

# Sauce
db    = require './saucedb'
users = require './users'
chans = require './channels'
spam  = require './spamlogger'

# Common 
auth  = require '../common/session'
io    = require '../common/ioutil'
sio   = require '../common/socket'
log   = require '../common/logger'

# Node.js
net   = require 'net'
url   = require 'url'
color = require 'colors'

# Disable extra output
# (Possibly make it go somewhere else instead for logging?)
io.setDebug false
io.setVerbose false

# Loads user data
loadUsers = ->
    users.load (userlist) ->
        io.debug "Loaded #{(Object.keys userlist).length} users."


# Loads channel data
loadChannels = ->
    chans.load (chanlist) ->
        io.debug "Loaded #{(Object.keys chanlist).length} channels."
        updateClientChannels()
        
        
# Sends a channel list to all registered clients
updateClientChannels = (socket) ->
    data = []
    for _, e of chans.getAll()
        data.push {
            id    : e.id
            name  : e.name
            status: e.status
            bot   : e.bot
        }
    
    if socket?
        socket.emit 'channels', data
    else
        socket.emit 'channels', data for socket in server.sockets when socket.isClient?


weblog = new log.Logger Sauce.Path, 'updates.log'

# Special user map for twitch admins and staff
specialUsers = { }

# SauceBot connection handler class
class SauceBot
    
    constructor: (@socket) ->
        
        # Message handler
        @socket.on 'msg', (data) =>
            try
                @handle data
            catch error
                @sendError "Syntax error: #{error}"
                io.error error + "\n" + error.stack
        
        # Private message handler
        @socket.on 'pm', (data) =>
            try
                @handlePM data
            catch error
                @sendError "Error parsing PM: #{error}"
                io.error error

                
        # Update handler
        @socket.on 'upd', (data) =>
            try
                @handleUpdate data
            catch error
                @sendError "#{error}"
                io.error error
        
        # Request handler
        @socket.on 'get', (data) =>
            try
                @handleGet data
            catch error
                @sendError "#{error}"
                io.error error
            

    # Message (msg):
    #  * chan: [REQ] Source channel
    #  * user: [REQ] Source user
    #  ? op  : [OPT] Source user's op status: 1/0
    #  * msg : [REQ] Message
    #
    handle: (json) ->
        chan      = json.chan

        # Normalize json.op
        json.op   = if json.op then 1 else null

        # Handle the message
        chans.handle chan, json,
            say       : (data)       => @say        chan, data
            ban       : (data)       => @ban        chan, data
            unban     : (data)       => @unban      chan, data
            clear     : (data)       => @timeout    chan, data, 2
            timeout   : (data, time) => @timeout    chan, data, time
            commercial:              => @commercial chan
            

    # Private Message (pm):
    # * user: [REQ] Source user
    # * msg : [REQ] Message
    #
    handlePM: (json) ->
        {user, msg} = json

        if user is 'jtv'
            # Handle jtv messages:
            # - "you are not a moderator in this channel"
            # - "the user you are trying to ban is a moderator"
            # - ...
            if m = /^SPECIALUSER\s+(\w+)\s+(\w+)/.exec msg
                [_, name, role] = m
                console.log name.blue.inverse + ": " + role
                specialUsers[name.toLowerCase()] = role.toLowerCase()

        else
            # Handle messages by normal people using IRC clients
            #  ... maybe

    # Update (upd):
    #  * cookie: [REQ] Session cookie for authentication
    #  ? chan  : [OPT] Source channel
    #  * type  : [REQ] Update type
    #
    # Types:
    #  + Module name: reloads module
    #  + Users      : reloads user data
    #  + Channels   : reloads channel data
    #  + Help       : notifies channel that help is coming
    #  + Spam       : reloads spam lists
    #
    handleUpdate: (json) ->
        {channel, user, type} = @getWebData json, true
        
        io.debug "Update from #{user.id}-#{user.name}: #{channel.name}##{type}"
        weblog.timestamp 'UPDATE', channel.id, channel.name, type, user.id, user.name
        
        switch type
            when 'Users'
                loadUsers()
                
            when 'Channels'
                loadChannels()
                
            when 'Help'
                if channel? and user.isGlobal()
                    @say channel.name, '[Help] ' + channel.getString('Base', 'help-incoming', user.name)

            when 'Spam'
                spam.reload()
                    
            when 'Timeout'
                {username} = json
                if username? and channel? and user.isMod channel.id
                    username = @fixUsername username
                    console.log "Timing out #{username} (#{channel.name})"
                    #@timeout channel.name, username, 10 * 60
                    
            when 'Ban'
                {username} = json
                if username? and channel? and user.isMod channel.id
                    username = @fixUsername username
                    console.log "Banning #{username} (#{channel.name})"
                    #@ban channel.name, username
                    
                
            else
                channel?.reloadModule type
                
    fixUsername: (name) ->
        name = name.replace /[^a-zA-Z0-9_]+/g, ''
        name = name.substring 0, 39 if name.length > 40
        return name
                
        
    # Requests (get):
    # * cookie: [REQ] Session cookie for authentication
    # ? chan  : [OPT] Target channel
    # * type  : [REQ] Request type
    #
    # Types:
    #  + Users   : Returns a list of usernames
    #  + Channels: Returns a list of channels
    handleGet: (json) ->
        {channel, user, type} = @getWebData json, false
                
        io.debug "Request from #{user.id}-#{user.name}: #{channel.name}##{type}"
        #weblog.timestamp 'REQUEST', channel.id, channel.name, type, user.id, user.name
        
        switch type
            when 'Users'
                @socket.emit 'users', (name for name, _ of (channel.usernames ? {}))
            
            when 'Channels'
                updateClientChannels @socket
                
                # Make sure the client gets channel updates
                @socket.isClient = true

        
    getWebData: (json, requireLogin) ->
        {cookie, chan, type} = json
        
        userID = auth.getUserID cookie
        
        if requireLogin
            throw new Error 'You are not logged in' unless userID?
        
        channel = chans.getById(chan) ? {
            name: 'N/A'
            id  : -1
        }

        user = users.getById(userID) ? {
            name: 'N/A'
            id  : -1
        }

        {
            'channel': channel
            'user'   : user
            'type'   : type
        }
            

    # Sends an error to the client
    #
    # Error (error):
    #  * msg: [REQ] Error message
    #
    sendError: (message) ->
        io.say '>> '.red + message

        @socket.emit 'error',
              msg  : message


    # Sends a 'say' message to the client
    #
    # Say (say):
    #  * chan: [REQ] Target channel
    #  * msg : [REQ] Message to send
    #
    say: (channel, message) ->
        io.say channel, message
        
        server.broadcast 'say',
            chan: channel
            msg : message

  
    # Sends a 'timeout' message to the client
    # - Times out the target user for 10 minutes
    #
    # Time out (timeout):
    #  * chan: [REQ] Target channel
    #  * msg : [REQ] Target user to time out
    #
    timeout: (channel, user, time) ->
        server.broadcast 'timeout',
            chan: channel
            user: user
            time: time
            
        
    # Sends a 'ban' message to the client
    # - Bans the target user
    #
    # Ban (ban):
    #  * chan: [REQ] Target channel
    #  * msg : [REQ] Target user to ban
    #
    ban: (channel, user) ->
        server.broadcast 'ban',
            chan: channel
            user: user


    # Sends an 'unban' message to the client
    # - Unbans the target user
    #
    # Unban (unban):
    #  * chan: [REQ] Target channel
    #  * msg : [REQ] Target user to unban
    #
    unban: (channel, user) ->
        server.broadcast 'unban',
            chan: channel
            user: user
        
    
    # Sends a 'commercial' message to the client
    # - Plays a commercial for partner channels
    #
    # Commercial (commercial):
    #  * chan: [REQ] Target channel
    #
    commercial: (channel) ->
        server.broadcast 'commercial',
            chan: channel

# Load data
io.debug 'Loading users...'
loadUsers()

io.debug 'Loading channels...'
loadChannels()

# Start server
server = new sio.Server Sauce.PORT,
    (socket) ->
        io.socket "Client connected"
        new SauceBot socket
    , (socket) ->
        io.socket "Client disconnected: #{socket.remoteAddress()}"
