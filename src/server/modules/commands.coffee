# SauceBot Module: Commands

Sauce = require '../sauce'
db    = require '../saucedb'
trig  = require '../trigger'
vars  = require '../vars'

io    = require '../ioutil'

{ # Import DTO classes
    ArrayDTO,
    ConfigDTO,
    HashDTO,
    EnumDTO
} = require '../dto'

# Module description
exports.name        = 'Commands'
exports.version     = '1.1'
exports.description = 'Custom commands handler'

io.module '[Commands] Init'

# Commands module
# - Handles:
#  !set <command> <message>
#  !unset <command> <message>
#  !<command>
#
class Commands
    constructor: (@channel) ->
        @commands = new HashDTO @channel, 'commands', 'cmdtrigger', 'message'

        @triggers = {}
        
    load: ->
        @channel.register  this, "set"  , Sauce.Level.Mod,
            (user,args,sendMessage) =>
                @cmdSet user, args, sendMessage
        @channel.register  this, "unset", Sauce.Level.Mod,
            (user,args,sendMessage) =>
                @cmdUnset user, args, sendMessage

        # Load custom commands
        @commands.load =>
            for cmd of @commands.data
                @addTrigger cmd

    unload:->
        myTriggers = @channel.listTriggers { module:this }
        @channel.unregister myTriggers...
        
    addTrigger: (cmd) ->
        # Do nothing if the user is just editing an existing command.
        return if @triggers[cmd]?

        # Create a simple trigger that looks up a key in @commands
        @triggers[cmd] = trig.buildTrigger  this, cmd, Sauce.Level.User,
            (user, args, sendMessage) =>
                parsed = vars.parse @channel, user, @commands.get(cmd)
                sendMessage parsed

        @channel.register @triggers[cmd]

    delTrigger: (cmd) ->
        # Do nothing if the trigger doesn't exist.
        return unless @triggers[cmd]?

        @channel.unregister @triggers[cmd]

        delete @triggers[cmd]


    # !(un)?set <command>  - Unset command
    cmdUnset: (user, args, sendMessage) ->
        unless args[0]?
            return sendMessage "Usage: !unset (name).  Only forgets commands made with !set."

        cmd = args[0]

        if @commands.data[cmd]? or @triggers[cmd]?
            @commands.remove cmd
            @delTrigger      cmd
            return sendMessage "Command unset: #{cmd}"
        

    # !set <command> <message>  - Set command
    # !set <command>            - Unset command
    cmdSet: (user, args, sendMessage) ->
        unless args[0]?
            return sendMessage "Usage: !set (name) (message).  !set (name) or !unset (name) to forget a command."

        # !set <command>
        if (args.length is 1)
            return @cmdUnset user, args, sendMessage

        cmd = (args.splice 0, 1)[0]
        msg = args.join ' '

        @commands.add cmd, msg
        @addTrigger   cmd

        return sendMessage "Command set: #{cmd}"

    handle: (user, msg, sendMessage) ->

exports.New = (channel) ->
    new Commands channel
    
