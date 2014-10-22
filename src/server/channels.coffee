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


graph = require '../common/grapher'
io    = require './ioutil'
mod   = require './module'

util  = require 'util'

# The names of all of the available modules
moduleNames = Object.keys mod.MODULES

# All of the channels currently loaded, indexed by their name in lowercase
channels = {}

# A convenience map of channel IDs to their respective channel name, again in
# lowercase
names = {}

# Returns the channel with the given lowercase name, i.e., the argument to this
# function must be lowercase to find anything.
#
# * name: the name of the channel to look up
# = the located channel, or undefined if it doesn't exist
exports.getByName = (name) ->
    channels[name]


# Returns the channel with the given channel ID.
#
# * id: the id of the channel to look up
# = the located channel, or undefined if it doesn't exist
exports.getById = (id) ->
    exports.getByName names[id]


# Returns all of the loaded channels, indexed by their lowercase name.
#
# = the map of all channel names to channel objects
exports.getAll = -> channels

# A Channel represents one channel (as in Twitch) or server (as in Minecraft)
# for the bot to monitor. Each channel can have independent modules and
# commands, and even the bot can appear with a different name in each channel.
# Localization can also be done on a per-channel basis. 
class Channel
    constructor: (data) ->
        @id     = data.chanid
        @name   = data.name
        @status = data.status
        @bot    = data.bot

        # All users who have spoken in the chat
        @usernames = {}

        @roles = {}

        @roles[role] = {} for key, role of Sauce.Role

        @modules = []
        @triggers = []
        @loadChannelModules()

        # Channel specific vars
        @vars = new Vars this

        # Channel modes configuration
        @modes = new ConfigDTO this, 'channelconfig', ['modonly', 'quiet']
        @modes.load()

        # Channel strings configuration
        @strings = new HashDTO this, 'strings', 'key', 'value'
        @strings.load()


    logEvent: (userid, username, module, action, object, oldVal, newVal) ->
        sql = 'INSERT INTO events (time, userid, username, channel, chanid, module, action, object, old, new) ' +
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
        
        db.query sql, [~~(Date.now()/1000), userid, username, @name, @id, module, action, object, oldVal, newVal]




    # Handles an interface request.
    handleInterface: (user, module, action, params, res, bot) ->
        if (user.getMod @id) < Sauce.Level.Mod
            return res.error "You are not authorized to perform this action"

        if not module
            @handleChannelUpdate user, action, params, res, bot
        else if (m = @getLoadedModule module)?
            m.update? user, action, params, res, bot
        else
            res.error "Invalid module #{module}"


    # Handles interface updates not related to a specific module.
    handleChannelUpdate: (user, action, params, res, bot) ->
        cuh = new ChannelUpdateHandler this, user, res, bot
        unless (handler = cuh["#{action}Act"])?
            res.error "Invalid action: \"#{action}\". Actions: #{cuh.getHandlerNames().join ', '}"

        try
            handler(params)
        catch err
            io.error "Interface update error (user=#{user.id}, act=#{action}, params=#{params}): " + err
            res.error "Error"


    # Returns whether a module with the specified name
    # has been loaded for this channel.
    getLoadedModule: (moduleName) ->
        for module in @modules
            return module if module.name is moduleName


    # Loads a module by its name and returns the module instance. If the module
    # has already been loaded, it is just reloaded.
    #
    # * moduleName: the name of the module to load
    # = the module that was either loaded or reloaded
    loadModule: (moduleName) ->
        module = @getLoadedModule moduleName

        if module?
            # The module instance already exists, so just reload it 
            module.loadModule()
        else
            try
                # Create a new instance of the module and then load it
                module = mod.instance moduleName, this
                module?.loadModule()
            catch error
                console.log error.stack
                io.error "Error loading module #{moduleName}: #{error}"

        return module


    # Reloads a module with a given name. This function is pretty much
    # identical to @loadModule.
    #
    # * moduleName: the module to reload
    reloadModule: (moduleName) ->
        @loadModule moduleName


    # Attempts to load all modules associated with this channel. Modules that
    # have already been loaded will not be reloaded, but those that were not
    # found in this load from the database will be unloaded, i.e., after a call
    # to this function, only those modules specified for this channel in the
    # database will be available. Therefore, to unload a module, remove its
    # entry from the database and then call this function.
    loadChannelModules: ->
        oldNames = ( module.name for module in @modules )
        newNames = []

        db.getChanDataEach @id, 'module', (result) =>
            # Load newly added
            unless result.module in oldNames
                module = @loadModule result?.module
                @modules.push module if module?

            newNames.push result.module
        , =>
            # Unload removed
            for module in @modules when module? and not (module.name in newNames)
                @unloadModule module


    # Unloads a module with a given name by calling the module's unload()
    # function and then removing it from the list of loaded modules.
    #
    # * module: the module to unload
    unloadModule: (module) ->
        module.unloadModule()
        @modules.splice @modules.indexOf(module), 1



    isSub: (username) ->
        return @hasRole(username, Sauce.Role.Subscriber)

    # Fetches any available data about a user given a {username, oplevel} pair.
    # The database is first checked to see if the user is registered, in which
    # case that data is returned (except that the maximum of the provided and
    # the database op levels is used). If the username matches the owner of the
    # channel, then the op level is set to the Owner level. If neither of these
    # cases are true, then a generic user object with an op level reflecting
    # the provided level is returned.
    #
    # * username: the username of the user to look up
    # * op: the assumed op level of the user being requested
    # = an object of the form {name, op, db}, corresponding to the name of the
    #   user, the op level of the user, and whether the data on the user was
    #   found in the database
    getUser: (username, op) ->
        # Set the op level to 0 if it's not a number
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
                id  : user.id
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
            # Just in case op is special, we make sure it's 1 or 0
            op  : if op then 1 else 0
            db  : false
        }


    # Handles a message by passing it on to all loaded modules and tirggers.
    # 
    # * data: the contents of the message
    # * bot: the bot delivering the message
    handle: (data, bot) ->
        user = @getUser data.user, data.op
        # Cache the op level of the user from the data we get
        @usernames[user.name.toLowerCase()] = user.op

        msg = data.msg
        graph.count "channels.input.#{@name.toLowerCase()}"
        
        for trigger in @triggers
            # Check for first match that the user is authorized to use, also
            # taking into account whether the channel is in mod-only mode
            if trigger.test(msg) and (user.op >= trigger.oplevel and (!@isModOnly() or user.op >= Sauce.Level.Mod))
                if (trigger.sub and @isSub(user.name)) or !trigger.sub
                    args = trigger.getArgs msg
                    trigger.execute user, args, bot
                    # We only want to run one trigger, so break here
                    break
        
        # Now pass the message on the our modules        
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
            argstrings = (String(arg) for arg in args)
            io.error "Bad number of arguments when registering trigger: " +
                     argstrings.join(" ")
            return false

        index = 0

        for t in @triggers
            index++ if trigger.priority >= t.priority

        @triggers.splice index, 0, trigger

        return true


    # Removes the given triggers from this channel.
    #
    # * triggersToRemove: the triggers to remove.
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


    unregisterFor: (module) ->
        # Unregister commands
        @triggers = (trigger for trigger in @triggers when trigger.module isnt module)

        # Unregister variables
        @vars.unregisterFor module


    # Changes the status of quiet mode.
    #
    # * status: Whether to activate quiet mode.
    setQuiet: (status) ->
        @modes.add 'quiet', status


    # Returns whether quiet mode is enabled.
    #
    # = whether quiet mode is active
    isQuiet: ->
        @modes.get 'quiet'


    # Changes the status of mod-only mode.
    #
    # * status: Whether to activate mod-only mode.
    setModOnly: (status) ->
        @modes.add 'modonly', status


    # Returns whether mod-only mode is enabled. Because mod-only mode is a
    # subset of quiet mode, this will also return true if quiet mode is active.
    #
    # = whether mod-only mode or quiet mode is active
    isModOnly: ->
        @modes.get('modonly') or @isQuiet()


    # Returns whether a user with a given name has been "seen", i.e., they have
    # sent a message, or are registered, in this channel.
    #
    # * name: the name to look up
    # = whether the user with that name is known by this channel
    hasSeen: (name) ->
        name.toLowerCase() in Object.keys @usernames
    

    # Adds a role to the user (admin, subscriber, turbo, staff)
    addRole: (username, role) ->
        @roles[role]?[username.toLowerCase()] = true


    # Returns whether the user has the specified role
    # Roles includes twitch admin, staff and subscriber
    hasRole: (username, role) ->
        return @roles[role]?[username.toLowerCase()]



    # Returns a localized string for this channel.
    #   Strings are on the form 'module-group-key'
    #   where 'module' is the source module name,
    #   and 'group-key' is the key used to fetch it.
    #
    #   Strings containing templates(e.g. @1@, @2@, ...)
    #   get them replaced by their corresponding args[N-1]
    #   value. For example, @1@ gets turned into the
    #   value of the optional args' list first element (args[0]).
    #   Templates with no corresponding args value are ignored.
    #
    #   If this channel doesn't have a localized
    #   version of the specified string, the default
    #   one is used instead, from the module's exported
    #   'strings' list.
    #
    #   For invalid keys with no localized or default
    #   values, the returned value is on the form:
    #   '[#key]' where key is 'moduleName-key'.
    #
    # Parameters:
    # * [STR] moduleName : The name of the source module defining this string
    # * [STR] key        : The string key
    # * [STR...] args    : An optional list of arguments for the string (for templates)
    #
    getString: (moduleName, key, args...) ->
        key   = moduleName.toLowerCase() + "-" + key
        value = @getStringValue key

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


    getStringValue: (key) ->
        return @strings.get(key) ? mod.getDefaultString(key) ? '[#' + key + ']'


    # Sets a channel specific string.
    # * key: The string key.
    # * value: The new custom string for this channel.
    # Note: throws an error on invalid key.
    setString: (key, value) ->
        unless mod.getDefaultString(key)?
            throw "No string with key \"#{key}\""

        @strings.add key, value


    # Resets a channel specific string back to its default value.
    # * key: The string key to reset.
    # Note: throws an error on invalid key.
    resetString: (key) ->
        unless mod.getDefaultString(key)?
            throw "No string with key \"#{key}\""

        @strings.remove key


# Helper class to handle channel interface update requests.
class ChannelUpdateHandler
    constructor: (@channel, @user, @res, @bot) ->


    # Checks the user's access level.
    # An error will be sent if the user does not have the required access level.
    # * level: The minimum access level which must be met.
    # = true if the user has access. false otherwise.
    checkAccessLevel: (level) ->
        if @user.isMod @channel.id, level
            return true
        else
            @res.error "You are not authorized to use this feature. Required level: #{Sauce.LevelStr level}"
            return false


    # Returns all handler method names
    getHandlerNames: ->
        (m[1] for name of this when (m = /^(.+)Act$/.exec name))


    # [Admin] say(message) -> OK
    sayAct: (params) =>
        return unless @checkAccessLevel Sauce.Level.Admin

        # Flood control
        last = @channel.lastSayAct ? 0
        now = Date.now()
        limit = 1000 * 60
        if (last + limit > now)
            return @res.error "You may only speak through the bot once a minute"

        @channel.lastSayAct = now

        {message} = params
        unless message?
            return @res.error "Missing parameter: key"

        message = message.trim().substring(0, 200)
        @bot.say "[#{@user.name}] #{message}"
        @res.ok()


    # strings() -> { stringKey: stringValue, ... }
    stringsAct: =>
        @res.send @channel.strings.get()


    # [Admin] string(key, val?) -> { stringKey: stringValue, ... }
    stringAct: (params) =>
        return unless @checkAccessLevel Sauce.Level.Admin

        {key, val} = params
        unless key?
            return @res.error "Missing parameters: key"

        key = key.toLowerCase().trim()

        if val?
            @channel.setString key, val.trim()
        else
            @channel.resetString key
        @res.send @channel.strings.get()


    # modes() -> { "modonly": 1/0, "quiet": 1/0 }
    modesAct: =>
        @res.send @channel.modes.get()


    # [Admin] mode(key, val) -> OK
    modeAct: (params) =>
        return unless @checkAccessLevel Sauce.Level.Admin

        {key, val} = params
        unless key? and val?
            return @res.error "Missing parameters: key, val"
        key = key.toLowerCase().trim()
        val = val.toLowerCase().trim() in ['on', 'true', '1']
        
        switch key
            when 'modonly' then @channel.setModOnly val
            when 'quiet'   then @channel.setQuiet val
            else return @res.error "Invalid mode. Modes: modonly, quiet"

        @res.ok()


    # mods() -> { username: level, ... }
    modsAct: =>
        levels = {}
        for id, level of users.getMods @channel.id
            levels[users.getName(id)] = level
        @res.send levels


    # mod(username, level) -> OK
    modAct: =>
       @res.ok()


    # modules() -> [ moduleName, ... ]
    modulesAct: =>
        @res.send (m.name for m in @channel.modules)



# Handles a message in the appropriate channel instance.
#
# * chan: the name of the channel receiving the message
# * data: the data of the message
# * bot: the bot instance responsible for delivering the message
exports.handle = (chan, data, bot) ->
    channel = channels[chan]
    if channel?
        channel.handle data, bot
    else
        io.debug "No such channel: #{chan}"


# Loads the channel list from the database, running a callback on completion.
#
# * finished: a callback taking the map of channel names to channels as its
#             only argument 
exports.load = (finished) ->
    newChannels = {}
    newNames    = {}

    db.getDataEach 'channel', (chan) ->
        id     = chan.chanid
        name   = chan.name.toLowerCase()
        status = chan.status

        # If a channel with that ID is loaded, update it
        if oldName = names[id]
            channel = channels[oldName]

            # Update channel name, status, botname and modules
            channel.status = status
            channel.name   = chan.name
            channel.bot    = chan.bot
            channel.loadChannelModules()

        # Otherwise, set up a new channel
        else
            channel = new Channel chan

        # Add channel to caches
        newChannels[name] = channel
        newNames[id]      = name

    , ->
        channels = newChannels
        names    = newNames

        finished? channels


exports.Channel = Channel
