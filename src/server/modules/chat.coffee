# SauceBot Module: Chat

Sauce = require '../sauce'
db    = require '../saucedb'
spam  = require '../spamlogger'

io    = require '../ioutil'
log   = require '../../common/logger'
fs    = require 'fs'

{Module} = require '../module'

# Module description
exports.name        = 'Chat'
exports.version     = '1.1'
exports.description = 'Chat monitoring and user listing'
exports.locked      = true

exports.strings = {
    'users-cleared' : 'Active users cleared.'
    'users-pick-one': 'Random user: @1@'
    'users-pick-n'  : '@1@ random users: @2@'
}

io.module '[Chat] Init'

# Mentions to easily find references to "Ravn", "SauceBot", etc.
mentions = new log.Logger Sauce.Logging.Root, "mentions.log"

# Load the spam lists
spam.reload()

class Chat extends Module
    constructor: (@channel) ->
        super @channel

        @log = new log.Logger Sauce.Logging.Root, "channels/#{@channel.name}.log"
        
        @users = {}
        
        
    writelog: (user, msg) ->
        @log.timestamp "#{if user.op then '@' else ' '}#{user.name}", msg
        
        if /ravn|sauce|sause|\brav\b|drunkbot|cloudbro|beardbot/i.test msg
            mentions.write new Date(), @channel.name, user.name, msg

    load:->
        userpicker = (user, args) =>
            if args[0]?
                @cmdPickNUsers args[0]
            else
                @cmdPickOneUser()

        @regCmd "pickuser" , Sauce.Level.Mod, userpicker
        @regCmd "pickusers", Sauce.Level.Mod, userpicker

        @regCmd "users clear", Sauce.Level.Mod,
            (user, args) =>
                @users = {}
                bot.say "[Users] " + @str('users-cleared')

        @regVar 'users', (user, args, cb) =>
                if not args[0]? then return cb Object.keys(@users).length
                
                cb switch args[0]
                    when 'count' then Object.keys(@users).length
                    when 'rand'  then @getRandomUser()
                    when 'random' then @getRandomUser()
                    else '$(error: use count or rand)'

        @regActs {
            # Chat.all()
            'all': (user, params, res) =>
                res.send Object.keys @users

            # Chat.random()
            'random': (user, params, res) =>
                num = Object.keys(@users).length
                rand = @getRandomUser()
                msg  = @users[rand]
                res.send count: num, user: rand, msg: msg

            # Chat.count()
            'count': (user, params, res) =>
                res.send Object.keys(@users).length

            # Chat.clear()
            'clear': (user, params, res) =>
                @users = {}
                res.ok()
        }


    cmdPickOneUser: ->
        rand  = @getRandomUser()
        bot.say "[Users] " + @str('users-pick-one', rand)


    cmdPickNUsers: (num) ->
        num = parseInt(num)

        if num < 2 or isNaN num
            return @cmdPickOneUser()

        names  = @getShuffledUserList()

        # Clamp number
        if num > 10
            num = 10
        if num > names.length
            num = names.length

        picked = (names[i] for i in [0..num-1]).join ', '
        bot.say "[Users] " + @str('users-pick-n', num, picked)
        
        
    getRandomUser: ->
        list = Object.keys @users
        return "N/A" unless list.length
        
        list[~~(Math.random() * list.length)]
        

    getShuffledUserList: ->
        list = Object.keys @users
        i = list.length
        return list if i is 0

        # Fisher-Yates
        while --i
            j = Math.floor(Math.random() * (i + 1))
            [list[i], list[j]] = [list[j], list[i]]

        return list
        

    handle: (user, msg) ->
        @writelog user, msg
        @users[user.name] = msg
        spam.run @channel.id, user.name, msg


exports.New = (channel) ->
    new Chat channel
    
