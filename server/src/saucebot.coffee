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

# Utility
io    = require './ioutil'

# Node.js
sio   = require 'socket.io'
net   = require 'net'
sys   = require 'sys'
url   = require 'url'
color = require 'colors'

# Load users from the database
io.debug 'Loading users...'
users.load (userlist) ->
    io.debug "Loaded #{(Object.keys userlist).length} users."

# Load channels from the database
io.debug 'Loading channels...'
chans.load (chanlist) ->
    io.debug "Loaded #{(Object.keys chanlist).length} channels."


# SauceBot connection handler class
class SauceBot
    
    constructor: (@socket) ->

        # Message handler
        @socket.on 'msg', (data) =>
            try
                @handle data
            catch error
                @sendError "Syntax error: #{error}"
                io.error error
            
                
        # Update handler
        @socket.on 'upd', (data) =>
            try
                @handleUpdate data
            catch error
                @sendError "Syntax error: #{error}"
                io.error error
            

    # Message (msg):
    #  * chan: [REQ] Source channel
    #  * user: [REQ] Source user
    #  ? op  : [OPT] Source user's op status: 1/0
    #  ? cmd : [OPT] Command
    #  ? args: [OPT] Arguments
    #
    handle: (json) ->
       chan      = json.chan

        # Normalize json.op
        json.op   = if json.op then 1 else null

        # Split the arguments by space
        json.args = json.args.split ' '

        # Handle the message
        chans.handle chan, json, (data) =>
            @say chan, "#{io.noise()} #{data}"
        , =>
            
            
    # Update (upd):
    #  * chan: [REQ] Source channel
    #  * type: [REQ] Update type
    #  ? user: [OPT] User that performed the update
    #
    # Types:
    #  + Module name: reloads module
    #  + Users      : reloads user data
    #  + Channels   : reloads channel data
    #
    handleUpdate: (json) ->
        # TODO
            

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

        @socket.emit action,
                chan: channel
                msg : message


server = sio.listen Sauce.PORT
server.set 'log level', 1
io.say "Server started on port #{Sauce.PORT}".cyan

server.sockets.on 'connection', (socket) ->
    io.say 'Client connected: '.magenta + socket.handshake.address.address
    new SauceBot socket

