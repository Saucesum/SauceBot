# SauceBot channel data

Sauce = require './sauce'

db     = require './saucedb'
users  = require './users'
trig   = require './trigger'
{Vars} = require './vars'
{
    ConfigDTO,
    HashDTO
} = require './dto'


io    = require './ioutil'
mod   = require './module'

util  = require 'util'

# Module names
moduleNames = Object.keys mod.MODULES

# Channel list - indexed by channel name
channels = {}

# Name list for quick chanid -> channel name lookup
names = {}

# Returns a channel by its name in lowercase
exports.getByName = (name) ->
    channels[name]
    

# Returns a channel by its ChanID
exports.getById = (id) ->
    exports.getByName names[id]


class Channel
    constructor: (data) ->
        @id   = data.chanid
        @name = data.name
        @desc = data.description
    
        @usernames = {}
    
        @modules = []
        @triggers = []
        @loadChannelModules()
        
        @vars = new Vars @
        
        # Channel modes configuration
        @modes = new ConfigDTO @, 'channelconfig', ['modonly', 'quiet']
        @modes.load()

        # Channel strings configuration
        @strings = new HashDTO @, 'strings', 'key', 'value'
        @strings.load()

    
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
        
        if module?
            module.load()
        else
            try
                # Initialize and load the module
                module = mod.instance moduleName, this
                module.load()
            catch error
                io.error "Error loading module #{moduleName}: #{error}"
        
        return module
        
    
    reloadModule: (moduleName) ->
        io.debug "Attempting to reload module #{moduleName}..."
        @loadModule moduleName
        
    
    # Attempts to load all modules associated with this channel.
    #
    # Calling this multiple times only loads each modules once,
    # unless they were unloaded first.
    #
    # To unload a module, remove its entry from the database
    # and call this again.
    loadChannelModules: ->
        oldNames = ( module.name for module in @modules )
        newNames = []
        
        db.getChanDataEach @id, 'module', (result) =>
            # Load newly added
            unless result.module in oldNames
                @modules.push @loadModule result.module

            newNames.push result.module
        , =>
            # Unload removed
            for module in @modules when module? and not (module.name in newNames)
                @unloadModule module
            io.debug "Done loading #{@modules.length} modules for #{@name}"
            
            
    unloadModule: (module) ->
        module.unload()
        @modules.splice @modules.indexOf(module), 1
            
            
    # Returns a {name, op}-object for the specified user.
    #
    # If op is passed as an argument, it is used instead of
    # the user's moderator level for the channel.
    getUser: (username, op) ->
        op or= 0
        
        chan = @id
        user = users.getByName username
        
        # If the user is in the database, fetch their mod level
        if (user?)
            cmod = (user.getMod chan) ? 0
            
            return {
                name: user.name
                op  : Math.max(op, cmod)
                db  : true
            }
            
        # If the user's name is the same as the channel's name,
        # they're the broadcaster, i.e. the owner.
        if username.toLowerCase() is @name.toLowerCase()
            return {
                name: @name
                op  : Sauce.Level.Owner
                db  : false
            }
            
        # Otherwise just return their IRC op level
        return {
            name: username
            op  : if op then 1 else 0
            db  : false
        }


    # Handles a message by passing it on to all loaded modules.
    handle: (data, bot) ->
        user = @getUser data.user, data.op
        @usernames[user.name.toLowerCase()] = user.op
        
        msg = data.msg
        
        for trigger in @triggers
            # check for first match that the user is authorized to use
            if trigger.test(msg) and (user.op >= trigger.oplevel and (!@isModOnly() or user.op >= Sauce.Level.Mod)) 
                args = trigger.getArgs msg
                trigger.execute user, args, bot
                break
                
        for module in @modules
            module.handle user, msg, bot


    # register(trigger)   - Registers a Trigger
    # register(module,name,callback)   - Registers a Trigger built from
    #                                    args using buildTrigger
    register: (args...) ->
        # handle pseudo-overloads
        switch args.length
          when 1
            [trigger] = args
          when 4
            trigger = trig.buildTrigger args...
          else
            argstrings = String(arg) for arg in args
            io.error "Bad number of arguments when registering trigger: " +
                     argstrings.join(" ")
            return false

        index = 0

        for t in @triggers
            index++ if trigger.priority >= t.priority

        @triggers.splice index, 0, trigger

        return true


    unregister: (triggersToRemove...) ->
        @triggers = (elem for elem in @triggers when not (elem in triggersToRemove))


    # listTriggers (obj) returns a list of registered triggers in the channel.
    # Any attributes defined on the restrictions object will be matched against
    #  like-named attributes on the triggers to limit results.
    listTriggers: (restrictions={}) ->
        results = @triggers

        for attr, value of restrictions
            results = (elem for elem in results when (elem[attr] is value))

        results
        
        
    # Returns whether quiet mode is enabled
    isQuiet: ->
        @modes.get 'quiet'
    
    # Returns whether mod-only mode is enabled
    isModOnly: ->
        @modes.get('modonly') or @isQuiet()
        
    
    hasSeen: (name) ->
        name.toLowerCase() in Object.keys @usernames


    getString: (module, key, args...) ->
        key   = module.name.toLowerCase() + "-" + key
        value = @strings.get(key) ? mod.getDefaultString(key) ? '[#' + key + ']'
        
        for arg, argnum in args
            elem = "@#{argnum + 1}@"
            len  = elem.length

            idx  = 0
            until ((idx = value.indexOf elem, idx) is -1)
                prefix = value.substring(0, idx)
                suffix = value.substring(idx + len)
                msg = prefix + arg + suffix
                idx = prefix.length + arg.length
                value = msg

        return value

# Handles a message in the appropriate channel instance
exports.handle = (chan, data, bot) ->
    channel = channels[chan]
    if channel?
        channel.handle data, bot
    else
        io.debug "No such channel: #{chan}"


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
            channel.name = chan.name
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
            
