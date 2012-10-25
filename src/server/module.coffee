# SauceBot Module Loader

fs = require 'fs'

io        = require './ioutil'
db        = require './saucedb'
Sauce     = require './sauce'
{HashDTO} = require './dto'

PATH = __dirname + '/modules/'

exports.MODULES = {}

INFO_TABLE = 'moduleinfo'
STRS_TABLE  = 'strings'

# Fake channel for "default-data" like default strings.
defaultChannel = {
    id   : 0
    name : 'Default'
}

# DTO to store module strings
strDTO  = new HashDTO defaultChannel, STRS_TABLE, 'key', 'value'

# Loads a module with the given file name, minus the extension, so that it can
# be instantiated by the channels.
#
# Note: the name of the module, once loaded, might not be the same as the name
# of the file.
#
# * name: the file name of the module to load
loadModule = (name) ->
    try
        module = require "#{PATH}#{name.toLowerCase()}"
        io.debug "Loaded module #{module.name}(#{name.toLowerCase()}) v#{module.version}"
        
        exports.MODULES[module.name] = module
        
        {name, description, version} = module
        locked       = (if module.locked then 1 else 0)
        defaultstate = (if module.ignore then 0 else 1)
        
        # Update the module info table
        db.addData INFO_TABLE, ['name', 'description', 'version', 'defaultstate', 'locked'], [[name, description, version, defaultstate, locked]]

        return module
    catch error
      io.error "Could not load module #{name}: #{error}"
      return null



initialize = ->
    db.clearTable INFO_TABLE

    # Configure strings table
    strings = {}

    # Watch the module file path for any new .js files that can be loaded as
    # modules, and add them to our list of modules.
    fs.readdirSync(PATH).forEach (file) ->
        return unless match = /(\w+)\.js$/i.exec file
        return unless (module = loadModule(match[1]))?
        
        stringBase = module.name.toLowerCase()
    
        # Also update any strings that are loaded by this module
        for k, v of (module.strings ? {})
            key = "#{stringBase}-#{k}"
            strings[key] = v
    
    # Update the default string values in case they've been modified.
    strDTO.set strings
    
exports.getDefaultString = (key) ->
    strDTO.get key
 
# Attempts to instantiate a module of a given name for a channel by first
# checking if the file definition part exists, then calling the New function of
# the module definition on the channel, and finally populating some additional
# variables.
#
# * name: the name of the module
# * chan: the channel object that the module is being instantiated for
exports.instance = (name, chan) ->
    if (!exports.MODULES[name]?)
        throw new Error "No such module '#{name}'" unless loadModule name
        
    module = exports.MODULES[name]
    
    if (!module.New?)
        throw new Error "Invalid module '#{name}'"
        
    obj = module.New chan
    
    obj.name        = module.name
    obj.description = module.description
    obj.version     = module.version

    return obj


# Base class from which all modules inherit.
class Module

    # Constructs a module object.
    #
    # * channel: The parent channel object.
    constructor: (@channel) ->
        @loaded = false


    # Loads the module.
    loadModule: ->
        @unloadModule()
        @loaded = true
        io.module "[#{@getModuleName()}] Loading for #{@channel.id}: #{@channel.name}"
        @load()


    # Returns this module's class name.
    # Useful for debugging.
    getModuleName: ->
        @constructor.name


    # Unloads the module.
    # This removes all registered commands and variables.
    unloadModule: ->
        return unless @loaded
        @loaded = false
        
        io.module "[#{@getModuleName()}] Unloading from #{@channel.id}: #{@channel.name}"
        @channel.unregisterFor this
        @unload()


    # Registers a command.
    #
    # * trigger: Command trigger.
    # * level  : (optional) Minimum user level to trigger command.
    # * fn     : The trigger callback. Called as fn(user, args, bot).
    regCmd: (trigger, level, fn) ->
        unless fn?
            fn = level
            # No level specified, use default.
            level = Sauce.Level.User

        @channel.register this, trigger, level, fn


    # Registers a variable.
    #
    # * name: The variable name.
    # * fn  : The variable callback. Called as fn(user, args, cb)
    #         where cb must be called with the variable value.
    regVar: (name, fn) ->
        @channel.vars.register this, name, fn


    # Returns a named string for this channel.
    #
    # * key : The key of the string. Usually "group-name"
    # * args: Optional arguments to substitute in the string.
    str: (key, args...) ->
        @channel.getString @getModuleName(), key, args...

    
    # Unimplemented methods:
    load  : -> 0
    unload: -> 0
    handle: -> 0


exports.Module = Module

initialize()
