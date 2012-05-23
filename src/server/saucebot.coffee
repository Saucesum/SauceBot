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

# Common 
auth  = require '../common/session'
io    = require '../common/ioutil'
sio   = require '../common/socket'
log   = require '../common/logger' 

# Node.js
net   = require 'net'
url   = require 'url'
color = require 'colors'

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


weblog = new log.Logger Sauce.Path, 'updates.log'


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
            
                
        # Update handler
        @socket.on 'upd', (data) =>
            try
                @handleUpdate data
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
            
            
    # Update (upd):
    #  * cookie: [REQ] Session cookie for authentication
    #  ? chan  : [OPT] Source channel
    #  * type  : [REQ] Update type
    #
    # Types:
    #  + Module name: reloads module
    #  + Users      : reloads user data
    #  + Channels   : reloads channel data
    #
    handleUpdate: (json) ->
        {cookie, chan, type} = json
        
        userID = auth.getUserID cookie
        
        throw new Error 'You are not logged in' unless userID?
        
        channel = chans.getById(chan)
        chanName = if channel? then channel.name else 'N/A'
        
        user = users.getById userID
        
        io.debug "Update from #{userID}-#{user.name}: #{chan}##{type}"
        weblog.timestamp 'UPDATE', chan, chanName, type, userID, user.name
        
        switch type
            when 'Users'
                loadUsers()
                
            when 'Channels'
                loadChannels()
                
            else
                channel = chans.getById chan
                channel?.reloadModule type
                
                
            

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
        io.say '>> '.magenta + "say #{channel}: #{message}"
        
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
