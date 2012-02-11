# SauceBot channel data

Sauce = require './sauce'

db    = require './saucedb'
users = require './users'

io    = require './ioutil'
mod   = require './module'

sys   = require 'sys'

# Module names
moduleNames = Object.keys mod.MODULES

# Channel list - indexed by channel name
channels = {}

# Name list for quick chanid -> channel name lookup
names = {}

class Channel
    constructor: (data) ->
        @id   = data.chanid
        @name = data.name
        @desc = data.description
    
        @modules = []
        @triggers = []
        @loadChannelModules()
    
    
    # Returns whether a module with the specified name
    # has been loaded for this channel.
    getLoadedModule: (moduleName) ->
        for module in @modules
            return module if module.name is moduleName
    
    
    # Loads a module by its name and returns the module instance.
    #
    # Note: This *only* loads unloaded modules.
    #       Already loaded modules get returned as-is.
    loadModule: (moduleName) ->
        module = @getLoadedModule moduleName
        
        unless module?
            try
                # Initialize and load the module
                module = mod.instance moduleName, this
                module.load()
            catch error
                io.error "Error loading module #{moduleName}: #{error}"
        
        return module
        
    
    # Attempts to load all modules associated with this channel.
    #
    # Calling this multiple times only loads each modules once,
    # unless they were unloaded first.
    #
    # To unload a module, remove its entry from the database
    # and call this again.
    loadChannelModules: ->
        newModules = []
        
        db.getChanDataEach @id, 'module', (result) =>
            module = @loadModule result.module
            newModules.push module
        , =>
            @modules = newModules
            io.debug "Done loading modules for #{@name}"
            
            
    # Returns a {name, op}-object for the specified user.
    #
    # If op is passed as an argument, it is used instead of
    # the user's moderator level for the channel.
    getUser: (username, op) ->
        op or= null
        
        chan = @name
        user = users.getByName username
        
        if (user?)
            return {
                name: user.name
                op  : op or user.isMod chan
            }
        return {
            name: username
            op  : op
        }


    # Handles a message by passing it on to all loaded modules.
    handle: (data, sendMessage, finished) ->
        user      = @getUser data.user, data.op
        command   = data.cmd or ''
        arguments = data.args

        msg = data.cmd.cat data.args.join ' ' # TODO: Find out how to get the full message string. I don't know where this object is made.
        
        for trigger in @triggers
            if trigger.matches msg
                trigger.execute user, command, args, sendMessage
                break

        finished?()

    register: (trigger) ->
        index = 0

        for t in @triggers
            index++ if trigger.priority >= t.priority

        @triggers.splice index, 0, trigger



# Handles a message in the appropriate channel instance
exports.handle = (channel, data, sendMessage, finished) ->
    channels[channel].handle data, sendMessage, finished

# Loads the channel list
exports.load = (finished) ->
    newChannels = {}
    newNames    = {}
    
    db.getDataEach 'channel', (chan) ->
        id   = chan.chanid
        name = chan.name.toLowerCase()
        desc = chan.description
        
        # If a channel with that ID is loaded, update it.
        if oldName = names[id]
            channel = channels[oldName]

            # Update channel name, description and modules.
            channel.desc = desc
            channel.name = name
            channel.loadChannelModules()
            
        # Otherwise, set up a new channel.
        else
            channel = new Channel chan
            
        # Add channel to caches
        newChannels[name] = channel
        newNames[id]      = name
        
    , ->
        channels = newChannels
        names    = newNames
        
        finished? channels
            
