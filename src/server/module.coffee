# SauceBot Module Loader

fs = require 'fs'
io = require './ioutil'
db = require './saucedb'
{HashDTO} = require './dto'

PATH = './modules/'

exports.MODULES = {}

INFO_TABLE = 'moduleinfo'
STRS_TABLE  = 'strings'

# Fake channel for "default-data" like default strings.
defaultChannel = {
    id   : 0
    name : 'Default'
}

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


db.clearTable INFO_TABLE

# Configure strings table
strDTO  = new HashDTO defaultChannel, STRS_TABLE, 'key', 'value'
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
    
    obj.str = (key, args...) ->
        chan.getString obj.name, key, args...

    return obj
