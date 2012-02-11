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
        @loadChannelModules()
    
    
    getModule: (moduleName) ->
        for module in @modules
            return module if module.name is moduleName
    
    
    getLoadedModule: (moduleName) ->
        module = @getModule moduleName
        
        unless module?
            try
                # Initialize and load the module
                module = mod.instance moduleName, this
                module.load()
            catch error
                io.error "Error loading module #{moduleName}: #{error}"
        
        return module
        
    
    loadChannelModules: ->
        newModules = []
        
        db.getChanDataEach @id, 'module', (result) =>
            module = @getLoadedModule result.module
            newModules.push module
        , =>
            @modules = newModules
            io.debug "Done loading modules for #{@name}"
            
            
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

    handle: (data, sendMessage, finished) ->
        user      = @getUser data.user, data.op
        command   = data.cmd or ''
        arguments = data.args
        
        for module in @modules
            module.handle user, command, arguments, sendMessage

        finished?()



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
            
