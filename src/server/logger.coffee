# Logger utility

Sauce = require './sauce'

fs = require 'fs'

class Logger
    constructor: (@name) ->
        @file = Sauce.Path + 'logs/' + @name
        
        
    write: (args...) ->
        log = fs.createWriteStream @file,
            flags   : 'a'
            encoding: 'utf8'
                    
        log.on 'error', (err) ->
            console.log err
    
        log.write args.join('\t') + "\n"
        log.destroySoon()
        

    timestamp: (args...) ->
        @write getTime(), args...


getTime = ->
    Math.floor new Date()/1000
    

exports.Logger = Logger