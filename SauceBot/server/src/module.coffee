# SauceBot Module Loader

fs = require 'fs'
io = require './ioutil'

PATH = './modules/'

exports.MODULES = {}

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

 
 
exports.instance = (name) ->
    if (!exports.MODULES[name]?)
        throw new Error "No such module '#{name}'" unless loadModule name
        
    module = exports.MODULES[name]
    
    if (!module.New?)
        throw new Error "Invalid module '#{name}"
        
    module.New()
