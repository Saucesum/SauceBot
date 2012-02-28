# SauceBot Module: Monitor

Sauce = require '../sauce'
db    = require '../saucedb'
trig  = require '../trigger'

io    = require '../ioutil'
vars  = require '../vars'

# Module description
exports.name        = 'Monitor'
exports.version     = '1.0'
exports.description = 'Channel monitor'

io.module '[Monitor] Init'


class Monitor
    constructor: (@channel) ->
        @loaded = false

    load:->
        return if @loaded
        @loaded = true
        
        io.module "[Monitor] Loading for #{@channel.id}: #{@channel.name}"              


    unload:->
        return unless @loaded
        @loaded = false
        
        io.module "[Monitor] Unloading from #{@channel.id}: #{@channel.name}"


    handle: (user, msg, bot) ->
        console.log "#{@channel.id}\t#{user}\t#{msg}"


exports.New = (channel) ->
    new Monitor channel
    
