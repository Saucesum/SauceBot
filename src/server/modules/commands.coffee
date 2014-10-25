# SauceBot Module: Commands

Sauce = require '../sauce'
db    = require '../saucedb'
trig  = require '../trigger'
vars  = require '../vars'

io    = require '../ioutil'

util = require 'util'

{ # Import DTO classes
    ArrayDTO,
    ConfigDTO,
    HashDTO,
    BucketDTO,
    EnumDTO
} = require '../dto'

{Module} = require '../module'

# Module description
exports.name        = 'Commands'
exports.version     = '1.2'
exports.description = 'Custom commands handler'

exports.strings = {
    # Errors
    'err-usage'          : 'Usage: @1@'
    'err-only-forget-set': 'Only forgets commands made with @1@.'
    'err-to-forget'      : '@1@ or @2@ to forget a command.'

    # Actions
    'action-sub-set': 'Sub-command set: @1@'
    'action-mod-set': 'Mod-command set: @1@'
    'action-set'    : 'Command set: @1@'
    'action-unset'  : 'Command unset: @1@'
}

io.module '[Commands] Init'

# Commands module
# - Handles:
#  !set <command> <message>
#  !setmod <command> <message>
#  !unset <command> <message>
#  !<command>
#
class Commands extends Module
    constructor: (@channel) ->
        super @channel
        @commands = new BucketDTO @channel, 'commands', 'cmdtrigger', ['message', 'level', 'sub']
        @remotes  = new BucketDTO @channel, 'remotefields', 'key', [ 'value', 'updatedby', 'updatetime' ]

        @triggers = {}
    
    
    load: ->
        @regCmd "set"     , Sauce.Level.Mod, @cmdSet
        @regCmd "setmod"  , Sauce.Level.Mod, @cmdSetMod
        @regCmd "setsub"  , Sauce.Level.Mod, @cmdSetSub
        @regCmd "unset"   , Sauce.Level.Mod, @cmdUnset

        @regCmd "isSub"   , Sauce.Level.User, @cmdIsSub

        @regCmd "remotes", Sauce.Level.Owner, @cmdRemotes
        @regCmd "setrem", Sauce.Level.Mod, @cmdSetRem

        # Load custom commands
        @commands.load =>
            for cmd, d of @commands.data
                @addTrigger cmd


        # Register interface actions
        @regActs {
            # Commands.get()
            'get': (user, params, res) =>
                data = {}
                for key, cmd of @commands.get()
                    data[key]     = msg: cmd.message
                    data[key].lvl = cmd.level if cmd.level
                    data[key].sub = cmd.sub if cmd.sub
                res.send data

            # Commands.set(key, val, lvl=0, sub=0)
            'set': (user, params, res) =>
                {key, val, lvl} = params
                unless key? and val?
                    return res.error "Missing attributes: key, val"

                old = @commands.get key

                @removeCommand key
                level = lvl ? Sauce.Level.User
                @setCommand key, val, level, sub
                @logEvent user, 'set', key, (old ? { }).message, val
                res.ok()

            # Commands.remove(key)
            'remove': (user, params, res) =>
                {key} = params
                unless key?
                    return res.error "Missing attribute: key"

                old = @commands.get key
                @logEvent user, 'remove', key, (old ? { }).message

                @removeCommand key
                res.ok()

            # Commands.clear()
            'clear': (user, params, res) =>
                @logEvent user, 'clear'
                @clearCommands()
                res.ok()

            # REMOTES

            # Commands.setremote(key, val)
            'setremote': (user, params, res) =>
                {key, val} = params
                unless key?
                    return res.error "Missing attribute: key"

                unless val?
                    @remotes.remove key
                else
                    old = @remotes.get key
                    @logEvent user, 'setremote', key, (old ? {}).value, val
                    @remotes.add key, {
                        value: val
                        updatedby: user.id
                        updatetime: ~~(Date.now()/1000)
                    }

                res.ok()

            # Commands.getremotes()
            'getremotes': (user, params, res) =>
                res.send @remotes.get()
        }


    unload:->
        @triggers = {}
        
        
    addTrigger: (cmd) ->
        # Do nothing if the user is just editing an existing command.
        return if @triggers[cmd]?
        
        level = @commands.get(cmd).level
        sub = @commands.get(cmd).sub

        # Create a simple trigger that looks up a key in @commands
        @triggers[cmd] = trig.buildTrigger  this, cmd, level, sub,
            (user, args, bot) =>
                data = @commands.get cmd
                unless data?
                    return io.error "No such command #{cmd}"

                @channel.vars.parse user, data.message, (args.join ' '), (parsed) ->
                    bot.say parsed


        @channel.register @triggers[cmd]
        
        varcmd = "!" + cmd.toLowerCase()
        
        @regVar varcmd, (user, args, cb) =>
            cb @channel.vars.strip @commands.get(cmd).message
            

    delTrigger: (cmd) ->
        # Do nothing if the trigger doesn't exist.
        return unless @triggers[cmd]?

        @channel.unregister @triggers[cmd]
        @channel.vars.unregister "!#{cmd.toLowerCase()}"

        delete @triggers[cmd]

    
    cmdIsSub: (user, args, bot) =>
        bot.say 'user ' + user.name + ' sub = ' + @channel.isSub(user.name)


    # !(un)?set <command>  - Unset command
    cmdUnset: (user, args, bot) =>
        unless args[0]?
            return bot.say @str('err-usage', '!unset <name>') + '. ' + @str('err-only-forget-set', '!set')

        cmd = args[0]

        a = @delCommandIgnoreCase cmd
        b = @delTriggerIgnoreCase cmd

        bot.say @str('action-unset', cmd) if a or b


    # Removes a command (not case sensitive)
    delCommandIgnoreCase: (cmd) ->
        cmd = cmd.toLowerCase()
        for k, v of @commands.get() when k.toLowerCase() is cmd
            @commands.remove k
            return true
        return false


    # Removes a trigger (not case sensitive)
    delTriggerIgnoreCase: (cmd) ->
        cmd = cmd.toLowerCase()
        for k, v of @triggers when k.toLowerCase() is cmd
            @delTrigger k
            return true
        return false


    # !set <command> <message>  - Set command
    # !set <command>            - Unset command
    cmdSet: (user, args, bot) =>
        unless args[0]?
            return bot.say @str('err-usage', '!set <name> <message>') + '. ' + @str('err-to-forget', '!set <name>', '!unset <name>')

        # !set <command>
        if (args.length is 1)
            return @cmdUnset user, args, bot
        else
            @cmdUnset user, args, { say: -> 0 }

        cmd  = (args.splice 0, 1)[0]
        msg  = args.join ' '
        @setCommand cmd, msg, Sauce.Level.User

        return bot.say @str('action-set', cmd)


    # !setmod <command> <message>  - Set moderator-only command
    # !setmod <command>            - Unset command
    cmdSetMod: (user, args, bot) =>
        unless args[0]?
            return bot.say @str('err-usage', '!setmod <name> <message>') + '. ' + @str('err-to-forget', '!setmod <name>', '!unset <name>')

        # !setmod <command>
        if (args.length is 1)
            return @cmdUnset user, args, bot
        else
            @cmdUnset user, args, { say: -> 0 }
        

        cmd  = (args.splice 0, 1)[0]
        msg  = args.join ' '
        @setCommand cmd, msg, Sauce.Level.Mod

        return bot.say @str('action-mod-set', cmd)
       
    # !setsub <command> <message> - Set Sub-only command (and higher)
    # !setsub <command> - Unset command
    cmdSetSub: (user, args, bot) =>
        unless args[0]?
            return bot.say @str('err-usage', '!setsub <name> <message>') + '. ' + @str('err-to-forget', '!setsub <name>', '!unset <name>')

        # !setsub <command>
        if(args.length is 1)
            return @cmdUnset user, args, bot
        else
            @cmdUnset user, args, { say: -> 0 }

        cmd = (args.splice 0, 1)[0]
        msg = args.join ' '
        @setCommand cmd, msg, false, true

        return bot.say @str('action-sub-set', cmd)

    # !remotes - Shows remote fields
    cmdRemotes: (user, args, bot) =>
        bot.say "[Remotes] " + JSON.stringify(@remotes.get()).substring(0, 400)


    # !setrem <key> <message> - Sets a remote
    cmdSetRem: (user, args, bot) =>
        unless args.length >= 2
            return bot.say "Remotes set usage: !setrem <key> <message>"

        key = (args.splice 0, 1)[0]
        msg = args.join ' '

        unless user.id?
            return bot.say "Only moderators registered on the web interface may set remote commands."

        @remotes.add key, {
            value: msg
            updatedby: user.id
            updatetime: ~~(Date.now()/1000)
        }
        bot.say "Remote set."

        

    setCommand: (cmd, msg, level, sub = 0) ->
        # Make sure people don't accidentally set "!!ip" as a command
        cmd = cmd.replace /^!/, ''
        return unless cmd.length > 0
        
        data =
            message: msg
            level  : level
            sub    : sub

        @commands.add cmd, data
        @addTrigger   cmd


    removeCommand: (cmd) ->
        @commands.remove cmd
        @delTrigger      cmd

    
    clearCommands: ->
        @commands.clear()
        for cmd, _ of @triggers
            @delTrigger cmd


exports.New = (channel) ->
    new Commands channel
    
