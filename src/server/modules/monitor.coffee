# SauceBot Module: Monitor

Sauce = require '../sauce'
db    = require '../saucedb'

io    = require '../ioutil'
log   = require '../../common/logger'
fs    = require 'fs'

# Module description
exports.name        = 'Monitor'
exports.version     = '1.1'
exports.description = 'Chat monitoring and user listing'
exports.locked      = true

exports.strings = {
    'users-cleared': 'Active users cleared.'
}

io.module '[Monitor] Init'

mentions = new log.Logger Sauce.Path, "mentions.log"

class Monitor
    constructor: (@channel) ->
        @loaded = false

        @log = new log.Logger Sauce.Path, "channels/#{@channel.name}.log"
        
        @users = {}
        
        
    writelog: (user, msg) ->
        @log.timestamp "#{if user.op then '@' else ' '}#{user.name}", msg
        
        if /ravn|sauce|sause|\brav\b|drunkbot|cloudbro/i.test msg
            mentions.write new Date(), @channel.name, user.name, msg

    load:->
        return if @loaded
        @loaded = true
        
        io.module "[Monitor] Loading for #{@channel.id}: #{@channel.name}"

        @channel.register this, "users clear", Sauce.Level.Mod,
            (user, args, bot) =>
                @users = {}
                bot.say "[Users] " + @str('users-cleared')

        @channel.vars.register 'users', (user, args) =>
                if not args[0]? then return Object.keys(@users).length
                
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
        
        list[~~(Math.random() * list.length)]
        
        
    handle: (user, msg, bot) ->
        @writelog user, msg
        @users[user.name] = 1


exports.New = (channel) ->
    new Monitor channel
    
