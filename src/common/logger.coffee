# Logger utility

fs   = require 'fs'
{tz} = require './time'

class Logger
    constructor: (@root, @name) ->
        @file = @root + 'logs/' + @name
        
        
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
    ~~ (tz(Date.now(), 'Europe/Oslo')/1000)
    

exports.Logger = Logger