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
log   = require './logger' 

# Common 
auth  = require '../common/session'
io    = require '../common/ioutil'
sio   = require '../common/socket'

# Node.js
net   = require 'net'
url   = require 'url'
color = require 'colors'

# Loads user data
loadUsers = ->
    users.load (userlist) ->
        io.debug "Loaded #{(Object.keys userlist).length} users."


# Loads channel data
loadChannels = ->
    chans.load (chanlist) ->
        io.debug "Loaded #{(Object.keys chanlist).length} channels."


weblog = new log.Logger 'updates.log'


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
            say    : (data) => @say     chan, data
            ban    : (data) => @ban     chan, data
            unban  : (data) => @unban   chan, data
            clear  : (data) => @clear   chan, data
            timeout: (data) => @timeout chan, data
            
            
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
        @send 'say', channel, message

  
    # Sends a 'timeout' message to the client
    # - Times out the target user for 10 minutes
    #
    # Time out (timeout):
    #  * chan: [REQ] Target channel
    #  * msg : [REQ] Target user to time out
    #
    timeout: (channel, user) ->
        @send 'timeout', channel, user
        
    
    # Sends a 'clear' message to the client
    # - Clears the targets messages
    #
    # Clear (clear):
    #  * chan: [REQ] Target channel
    #  * msg : [REQ] Target user to clear messages
    #
    clear: (channel, user) ->
        @send 'clear', channel, user
        
        
    # Sends a 'ban' message to the client
    # - Bans the target user
    #
    # Ban (ban):
    #  * chan: [REQ] Target channel
    #  * msg : [REQ] Target user to ban
    #
    ban: (channel, user) ->
        @send 'ban', channel, user


    # Sends an 'unban' message to the client
    # - Unbans the target user
    #
    # Unban (unban):
    #  * chan: [REQ] Target channel
    #  * msg : [REQ] Target user to unban
    #
    unban: (channel, user) ->
        @send 'unban', channel, user


    # Sends a message to the client
    send: (action, channel, message) ->
        io.say '>> '.magenta + "#{action} #{channel}: #{message}"

        server.broadcast action,
                chan: channel
                msg : message


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
