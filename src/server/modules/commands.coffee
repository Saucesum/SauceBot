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
        @commands = new BucketDTO @channel, 'commands', 'cmdtrigger', ['message', 'level']

        @triggers = {}
    
    
    load: ->
        @regCmd "set"     , Sauce.Level.Mod, @cmdSet
        @regCmd "setmod"  , Sauce.Level.Mod, @cmdSetMod
        @regCmd "unset"   , Sauce.Level.Mod, @cmdUnset

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
                res.send data

            # Commands.set(key, val, lvl=0)
            'set': (user, params, res) =>
                {key, val, lvl} = params
                unless key? and val?
                    return res.error "Missing attributes: key, val"

                @setCommand key, val, lvl ? Sauce.Level.User
                res.ok()

            # Commands.remove(key)
            'remove': (user, params, res) =>
                {key} = params
                unless key?
                    return res.error "Missing attribute: key"

                @removeCommand key
                res.ok()

            # Commands.clear()
            'clear': (user, params, res) =>
                @clearCommands()
                res.ok()
        }


    unload:->
        @triggers = {}
        
        
    addTrigger: (cmd) ->
        # Do nothing if the user is just editing an existing command.
        return if @triggers[cmd]?
        
        level = @commands.get(cmd).level

        # Create a simple trigger that looks up a key in @commands
        @triggers[cmd] = trig.buildTrigger  this, cmd, level,
            (user, args, bot) =>
                @channel.vars.parse user, @commands.get(cmd).message, (args.join ' '), (parsed) ->
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


    # !(un)?set <command>  - Unset command
    cmdUnset: (user, args, bot) =>
        unless args[0]?
            return bot.say @str('err-usage', '!unset <name>') + '. ' + @str('err-only-forget-set', '!set')

        cmd = args[0]

        if @commands.data[cmd]? or @triggers[cmd]?
            @commands.remove cmd
            @delTrigger      cmd
            return bot.say @str('action-unset', cmd)
        

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
        
        
    setCommand: (cmd, msg, level) ->
        data =
            message: msg
            level  : level

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
    
