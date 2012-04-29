# Logger utility

Sauce = require './sauce'

fs   = require 'fs'
time = require 'time'


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
    date = new time.Date()
    date.setTimezone 'CET'
    ~~ (date/1000)
    

exports.Logger = Logger