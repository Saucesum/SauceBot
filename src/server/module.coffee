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

fs.readdirSync(PATH).forEach (file) ->
    return unless match = /(\w+)\.js$/i.exec file
    return unless (module = loadModule(match[1]))?
    
    stringBase = module.name.toLowerCase()

    for k, v of (module.strings ? {})
        key = "#{stringBase}-#{k}"
        strings[key] = v

# Update the default string values in case they've been modified.
strDTO.set strings
 
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
