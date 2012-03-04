# SauceBot Module: Monitor

Sauce = require '../sauce'
db    = require '../saucedb'

io    = require '../ioutil'
fs    = require 'fs'

# Module description
exports.name        = 'Monitor'
exports.version     = '1.0'
exports.description = 'Chat monitoring'

io.module '[Monitor] Init'


class Monitor
    constructor: (@channel) ->
        @loaded = false
        @path = "/home/ravn/logs/#{@channel.name}.log"
        
        @users = {}
        
    writelog: (user, msg) ->
        # TODO: Change the path to something more relative
        @log.destroy() if @log?

        @log = fs.createWriteStream @path,
            flags: 'a'
            encoding: 'utf8'
        
        @log.on 'error', (errmsg) =>
            io.error "[Monitor] log error: #{errmsg}"

        @log.write "#{Math.floor new Date()/1000}\t#{if user.op then '@' else ' '}#{user.name}\t#{msg}\n"

    load:->
        return if @loaded
        @loaded = true
        
        io.module "[Monitor] Loading for #{@channel.id}: #{@channel.name}"
        
        @channel.register this, "users", Sauce.Level.Mod,
            (user, args, bot) =>
                bot.say "[Users] Active users: #{(user.toLowerCase() for user, val of @users).join ', ' }"


    unload:->
        return unless @loaded
        @loaded = false
        
        io.module "[Monitor] Unloading from #{@channel.id}: #{@channel.name}"
        myTriggers = @channel.listTriggers { module:this }
        @channel.unregister myTriggers...

    handle: (user, msg, bot) ->
        @writelog user, msg
        @users[user.name] = 1


exports.New = (channel) ->
    new Monitor channel
    
