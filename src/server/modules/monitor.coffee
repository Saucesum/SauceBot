# SauceBot Module: Monitor

Sauce = require '../sauce'
db    = require '../saucedb'

io    = require '../ioutil'
log   = require '../logger'
fs    = require 'fs'

# Module description
exports.name        = 'Monitor'
exports.version     = '1.1'
exports.description = 'Chat monitoring and user listing'
exports.locked      = true

io.module '[Monitor] Init'

mentions = new log.Logger "mentions.log"

class Monitor
    constructor: (@channel) ->
        @loaded = false

        @log = new log.Logger "#{@channel.name}.log"
        
        @users = {}
        
        
    writelog: (user, msg) ->
        @log.timestamp "#{if user.op then '@' else ' '}#{user.name}", msg
        
        if /ravn|sauce/i.test msg
            mentions.write new Date(), @channel.name, user.name, msg

    load:->
        return if @loaded
        @loaded = true
        
        io.module "[Monitor] Loading for #{@channel.id}: #{@channel.name}"
        
        @channel.register this, "users", Sauce.Level.Mod,
            (user, args, bot) =>
                bot.say "[Users] Active users: #{Object.keys(@users).join ', '}"
        
        @channel.register this, "users clear", Sauce.Level.Mod,
            (user, args, bot) =>
                @users = {}
                bot.say "[Users] Active users cleared."

        @channel.vars.register 'users', (user, args) =>
                if not args[0]? or args[0] is 'list'
                    return Object.keys(@users).join ', '
                
                switch args[0]
                    when 'count' then Object.keys(@users).length
                    when 'rand'  then @getRandomUser()
                    else 'undefined' 


    unload:->
        return unless @loaded
        @loaded = false
        
        io.module "[Monitor] Unloading from #{@channel.id}: #{@channel.name}"
        myTriggers = @channel.listTriggers { module:this }
        @channel.unregister myTriggers...
        
        @channel.vars.unregister 'users'
        
        
    getRandomUser: ->
        list = Object.keys @users
        return "N/A" unless list.length
        
        list[Math.floor(Math.random() * list.length)]
        
        

    handle: (user, msg, bot) ->
        @writelog user, msg
        @users[user.name] = 1


exports.New = (channel) ->
    new Monitor channel
    
