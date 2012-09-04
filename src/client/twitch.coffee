
# Node.js
color      = require 'colors'
term       = require 'readline'
util       = require 'util'
fs         = require 'fs'

# Sauce
io         = require '../common/ioutil'
config     = require '../common/config'
log        = require '../common/logger'
{Channel}  = require './saucechan'


# Set up logging
logger = new log.Logger logging.root, "jtv.log"
pmlog  = new log.Logger logging.root, "pm.log"


# Twitch Message Interface connection handler class
#
#  List of possible emits:
#  * error(source, reason)
#
class Twitch
    constructor: ->
        # Accounts: {username: {name, pass}}
        @accounts = {}
        
        # Connections: {'bot::channel': Channel}
        @connections = {}
        
        # Handlers: {handler: <callback>}
        @handlers = {}
        
        
    # Registers an emit-callback for this TMI.
    # * name: The emit-code to handle.
    # * callback: The callback associated with the emit.
    # Note: Any already existing handlers for that emit get removed.
    on: (name, callback) ->
        @handlers[name] = callback
        
    
    # Sends an emit to all registered handlers.
    # * name: The name of the handlers to call.
    # * data...: Arguments to call the handler with.
    emit: (name, data...) ->
        @handlers[name]?(data...)
        

    # Registers a Twitch.tv account to be used by the bot.
    # * name: Bot username. Case-sensitive.
    # * pass: Bot password.
    # = Returns the account object created.
    addAccount: (name, pass) ->
        @accounts[name.toLowerCase()] =
            name: name
            pass: pass
            

    # Returns an account object for the specified Twitch.tv account.
    # If no such account exists, undefined is returned.
    # * name: Bot username. Case-insensitive.
    getAccount: (name) ->
        @accounts[name.toLowerCase()]
        
    
    # Sets up a connection to the specified channel using the specified bot.
    # * chan: Channel name to connect to.
    # * bot: Bot name to use. Case-insensitive.
    # Note: If no such bot exists, an error is emitted.
    join: (chan, bot) ->
        account = @getAccount bot
        unless account?
            return @emit 'error', 'join', 'No such bot-account!'
            
        channel = @createChannel chan, account
        channel.connect()
        @connections[account.name + '::' + chan.toLowerCase()] = channel
        
        
    # Removes a connection from the specified channel using the specified bot.
    # * chan: Channel name to disconnect from.
    # * bot: Bot name to use. Case-insensitive.
    # Note: If no such connection exists, nothing happens.
    part: (chan, bot) ->
        return unless (account = @getAccount bot)?
        
        idx = account.name + '::' + chan.toLowerCase()
        
        @connections[idx]?.part()
        delete @connections[idx]
                    
    
    # Creates a new Channel object and connects all handlers.
    # * chan: Channel name.
    # * account: Bot account to set up with.
    # = Returns the channel object created.
    createChannel: (chan, account) ->
        channel = new Channel chan, account.name, account.pass
        
        channel.on 'message', (data) =>
            {from, message, op} = data
            
        channel.on 'pm', (data) =>
            {from, message} = data
            
        channel.on 'error', (data) =>
            @emit 'error', 'Channel/' + chan, "#{key}: #{val}" for key, val of data  
        
        channel.on 'connected', =>
            1 # ...
            
        channel.on 'connecting', =>
            1 # ...
            
        channel.on 'disconnecting', =>
            1 # ...
            
        return channel
        

exports.Twitch = Twitch