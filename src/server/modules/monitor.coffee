# SauceBot Module: Monitor

Sauce = require '../sauce'
db    = require '../saucedb'
spam  = require '../spamlogger'

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

# Mentions to easily find references to "Ravn", "SauceBot", etc.
mentions = new log.Logger Sauce.Path, "mentions.log"

# Load the spam lists
spam.reload()

class Monitor
    constructor: (@channel) ->
        @loaded = false

        @log = new log.Logger Sauce.Path, "channels/#{@channel.name}.log"
        
        @users = {}
        
        
    writelog: (user, msg) ->
        @log.timestamp "#{if user.op then '@' else ' '}#{user.name}", msg
        
        if /ravn|sauce|sause|\brav\b|drunkbot|cloudbro|beardbot/i.test msg
            mentions.write new Date(), @channel.name, user.name, msg

    load:->
        return if @loaded
        @loaded = true
        
        io.module "[Monitor] Loading for #{@channel.id}: #{@channel.name}"

        @channel.register this, "users clear", Sauce.Level.Mod,
            (user, args, bot) =>
                @users = {}
                bot.say "[Users] " + @str('users-cleared')

        @channel.vars.register 'users', (user, args, cb) =>
                if not args[0]? then return cb Object.keys(@users).length
                
                cb switch args[0]
                    when 'count' then Object.keys(@users).length
                    when 'rand'  then @getRandomUser()
                    when 'random' then @getRandomUser()
                    else '$(error: use count or rand)'


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
        spam.run @channel.id, user.name, msg


exports.New = (channel) ->
    new Monitor channel
    
