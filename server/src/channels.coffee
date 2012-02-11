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
    
    
    addModule: (moduleName) ->
        try
            module = mod.instance moduleName, this
            module.load()
            @modules.push module
        catch error
            io.error "Error loading module #{moduleName}: #{error}"
            io.debug error.stack
    
    loadChannelModules: ->
        db.getChanDataEach @id, 'module', (result) =>
            @addModule result.module
            io.debug "Channel #{@name} uses module #{result.module}"
        , =>
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

        msg = data.cmd.cat data.args.join ' ' # TODO: Find out how to get the full message string. I honestly don't know how.
        
        for trigger in @triggers
            if msg.match trigger.pattern
                trigger.execute user, command, args, sendMessage
                break

        finished?()

    register: (module, priority, pattern, callback) ->
        index = 0
        index++ for t in @triggers when priority >= t.priority

        @triggers.splice index, 0, {
            module  : module
            pattern : pattern
            execute : callback
            priority: priority
        }



# Handles a message in the appropriate channel instance
exports.handle = (channel, data, sendMessage, finished) ->
    channels[channel].handle data, sendMessage, finished

# Loads the channel list
exports.load = (finished) ->
    # Clear the channel list
    channels = {}
    names    = {}
    
    db.getDataEach 'channel', (chan) ->
        id   = chan.chanid
        name = chan.name.toLowerCase()
        desc = chan.description
        
        channel = new Channel chan
        
        # Add channel to caches
        channels[name] = channel
        names[id]      = name
        
    , ->
        finished? channels

    
