 ###########################################################
#                                                           #
# - Node.js implementation of the SauceBot Command Server - #
#                                                           #
 ###########################################################
 
# Config
Sauce = require './sauce'

# Common
auth  = require '../common/session'
io    = require '../common/ioutil'
sio   = require '../common/socket'
log   = require '../common/logger'
graph = require '../common/grapher'

# Set up logging
io.setLogger new log.Logger Sauce.Logging.Root, 'server.log'

weblog = new log.Logger Sauce.Logging.Root, 'updates.log'

activityLog = new log.Logger Sauce.Logging.Root, 'activity.json'


# Sauce
db    = require './saucedb'
users = require './users'
chans = require './channels'
spam  = require './spamlogger'

# Node.js
net   = require 'net'
fs    = require 'fs'
url   = require 'url'
color = require 'colors'
repl  = require 'repl'

# Client Types
Type = {
    Web : 'web'
    Chat: 'chat'
}

# Broadcasts a message to all clients with a certain type
broadcastType = (type, cmd, data) ->
    graph.count "output.#{cmd}"
    server.forAll (socket) ->
        if socket.type is type
            socket.emit cmd, data

# Loads user data
loadUsers = ->
    users.load (userlist) ->
        io.debug "Loaded #{(Object.keys userlist).length} users."


# Loads channel data
loadChannels = ->
    chans.load SauceEmitter, (chanlist) ->
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
            bot   : e.botName
        }
    
    if socket?
        socket.emit 'channels', data
    else
        broadcastType Type.Chat, 'channels', data


# Special user map for twitch admins and staff
specialUsers = { }


# SauceBot Message Emitter
class SauceEmitter

    # Creates a SauceEmitter for a channel.
    constructor: (@channel) ->
        

    # Sends a 'say' message to the clients.
    #
    # Say (say):
    #  * msg : [REQ] Message to send
    #
    say: (message) ->
        io.say @channel, message
        message = message.replace /\s+/g, ' '
        message = message.replace /</, '&lt;'
        message = message.replace />/, '&gt;'

        broadcastType Type.Chat, 'say',
            chan: @channel
            msg : message

  
    # Sends a 'timeout' message to the clients.
    # - Times out the target user for 10 minutes
    #
    # Time out (timeout):
    #  * msg  : [REQ] Target user to time out
    #  * time : [OPT] Time out length in seconds
    #
    timeout: (user, time) ->
        broadcastType Type.Chat, 'timeout',
            chan: @channel
            user: user
            time: time
            
    # Sends a 'timeout' message to the clients.
    # - Times out the target user for 2 seconds.
    #
    # Time out (timeout):
    #  * msg : [REQ] Target user to time out
    #
    clear: (user) ->
        @timeout user, 2

        
    # Sends a 'ban' message to the clients.
    # - Bans the target user
    #
    # Ban (ban):
    #  * msg : [REQ] Target user to ban
    #
    ban: (user) ->
        broadcastType Type.Chat, 'ban',
            chan: @channel
            user: user


    # Sends an 'unban' message to the clients.
    # - Unbans the target user
    #
    # Unban (unban):
    #  * msg : [REQ] Target user to unban
    #
    unban: (user) ->
        broadcastType Type.Chat, 'unban',
            chan: @channel
            user: user


# SauceBot connection handler class
class SauceBot
    
    constructor: (@socket) ->
        @socket.type = Type.Web
        @socket.name = 'Unknown'

        @socket.on 'register', (data) =>
            {type, name} = data

            @socket.type = type
            @socket.name = name

            io.socket "Client registered as #{type}::#{name} @ #{@socket.remoteAddress()}"

            if type is Type.Chat
                updateClientChannels @socket
        
        # Message handler
        @socket.on 'msg', (data) =>
            graph.count 'input.msg'
            try
                @handle data
            catch error
                @emitError "Syntax error: #{error}"
                io.error error + "\n" + error.stack
        
        # Private message handler
        @socket.on 'pm', (data) =>
            graph.count 'input.pm'
            try
                @handlePM data
            catch error
                @emitError "Error parsing PM: #{error}"
                io.error error

                
        # Update handler
        @socket.on 'upd', (data) =>
            graph.count 'input.upd'
            try
                @handleUpdate data
            catch error
                @emitError "#{error}"
                io.error error

        # Handle interface requests
        @socket.on 'int', (data) =>
            graph.count 'input.int'
            try
                @handleInterface data
            catch error
                @sendResult 0, error: error.toString()
                io.error error
        
        # Request handler
        @socket.on 'get', (data) =>
            graph.count 'input.get'
            try
                @handleGet data
            catch error
                @emitError "#{error}"
                io.error error

        # Activity list
        @socket.on 'activity', (data) =>
            activityLog.setText JSON.stringify(data.activity)
            

    # Sends an error to the active client.
    #
    # Error (error):
    #  * msg: [REQ] Error message
    #
    emitError: (message) ->
        io.say '>> '.red + message
        graph.count 'output.error'

        @socket.emit 'error',
              msg  : message


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
        chans.handle chan, json
            

    # Creates a web callback result object.
    createRes: ->
        # Web callbacks (closes the connection)
        ok   :        => @sendResult 1
        send : (data) => @sendResult 1, data
        error: (msg)  => @sendResult 0, error: msg


    # Private Message (pm):
    # * user: [REQ] Source user
    # * msg : [REQ] Message
    #
    handlePM: (json) ->
        {chan, user, msg} = json

        if user is 'jtv'
            # Handle jtv messages:
            # - "you are not a moderator in this channel"
            # - "the user you are trying to ban is a moderator"
            # - ...
            if m = /^SPECIALUSER\s+(\w+)\s+(\w+)/.exec msg
                [_, name, role] = m
                (chans.getByName chan)?.addRole name, role
                specialUsers[name.toLowerCase()] = role.toLowerCase()

            else if m = /^You are banned from talking in \S+ for (\d+)/.exec msg
                [time] = m
                io.say chan, "Banned for #{time} seconds".red

            else if /^You don't have permission to/.test msg
                io.say chan, "Not a moderator".magenta

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
    #  + Users     : reloads user data
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


    # Interface (int):
    # * cookie: [REQ] Session cookie for authentication
    # * chan  : [REQ] Target channel
    # * module: [REQ] Target module
    # * action: [REQ] Action
    # * getter: [OPT] Whether this is a getter action 
    #
    handleInterface: (data) ->
        {channel, user } = @getWebData data, true
        {module, action} = data

        if channel.id is -1 then throw new Error "Invalid channel"
        unless module?      then throw new Error "Missing parameter: module"
        unless action?      then throw new Error "Missing parameter: action"
        
        unless data.getter
            weblog.timestamp 'API', channel.id, channel.name, module + '/' + action, user.id, user.name

        # Create request callbacks
        res = @createRes()

        if user.global and action is 'Rejoin'
            broadcastType Type.Chat, 'rejoin', channel.name
            res.ok()
        else
            channel.handleInterface user, module, action, data, res


    # Sends a result and then closes the connection.
    sendResult: (res, data) ->
        @socket.emitRaw {
            result: res
            data  : data
        }
        @socket.close()
       
 
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
        
        switch type
            when 'Users'
                @socket.emit 'users', (name for name, _ of (channel.usernames ? {}))
            
            when 'Channels'
                updateClientChannels @socket


    # Parses web request data.
    # * json: An object containing the following fields:
    #           cookie: The user's session cookie.
    #           chan  : The target channel.
    #           type  : The specified type. (Optional)
    #
    # * requireLogin: Whether to require the user to be logged in.
    # = an object { channel: <chan object>, user: <user object>, type: json.type }
    getWebData: (json, requireLogin) ->
        {cookie, chan, type} = json
        
        userID = auth.getUserID cookie
        
        if requireLogin
            throw new Error 'You are not logged in' unless userID?
        
        channel = chans.getById(chan) ? chans.getByName(chan) ? {
            name: 'N/A'
            id  : -1
        }

        user = users.getById(userID) ? users.getNullUser()

        {
            'channel': channel
            'user'   : user
            'type'   : type
        }
        

# Load data
io.debug 'Loading users...'
loadUsers()

io.debug 'Loading channels...'
loadChannels()

# Start server
server = new sio.Server Sauce.Server.Port,
    (socket) ->
        new SauceBot socket
        graph.count 'server.connected'
    , (socket) ->
        if socket.type isnt Type.Web
            io.socket "Client disconnected: #{socket.type}::#{socket.name} @ #{socket.remoteAddress()}"
        graph.count 'server.disconnected'


# Start activity poller
setInterval ->
    broadcastType Type.Chat, 'activity'
, 60 * 1000



# Start REPL
saucerepl = repl.start input: process.stdin, output: process.stdout
saucerepl.context[key] = val for key, val of {
    channels: chans
    users:    users
    db:       db

    # Utility functions
    c: chans.getByName
    u: users.getByName
    reconnect: ->
        broadcastType Type.Chat, 'restart'
}
