# SauceBot Module Loader

fs = require 'fs'
io = require './ioutil'

PATH = './modules/'

exports.MODULES = {}

exports.PRI_TOP   = 0  # Reserved for what, if anything, needs it.
exports.PRI_HIGH  = 1  # Could be used for sub commands, like '!vm reset'
exports.PRI_MID   = 2  # For simple commands, like '!time'
exports.PRI_LOW   = 3  # For greedy commands, like counter creation.

fs.readdirSync(PATH).forEach (file) ->
    return unless match = /(\w+)\.js$/i.exec file
    try
        module = require(PATH + file)
        io.debug "Loaded module #{module.name}(#{match[1]}.js) v#{module.version}"
        exports.MODULES[module.name] = module

    catch error
      io.error "Could not load module #{match[1]}: #{error}"


loadModule = (name) ->
    try
        module = require "#{PATH}#{name.toLowerCase()}.js" 
        io.debug "Loaded module #{module.name}(#{name.toLowerCase()}.js) v#{module.version}"
        exports.MODULES[module.name] = module

    catch error
      io.error "Could not load module #{name}: #{error}"

 
 
exports.instance = (name, chan) ->
    if (!exports.MODULES[name]?)
        throw new Error "No such module '#{name}'" unless loadModule name
        
    module = exports.MODULES[name]
    
    if (!module.New?)
        throw new Error "Invalid module '#{name}'"
        
    module.New chan
