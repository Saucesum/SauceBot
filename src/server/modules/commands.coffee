# SauceBot Module: Commands

Sauce = require '../sauce'
db    = require '../saucedb'
trig  = require '../triggers'

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
        @channel.register  this, "set"  , Sauce.Level.Mod, @cmdSet
        @channel.register  this, "unset", Sauce.Level.Mod, @cmdUnset

        # Load custom commands
        @commands.load()

        # Register each command in its own closure wrapper
        for own cmd of @commands.data
            do @addTrigger cmd

    unload:->
        myTriggers = @channel.listTriggers { module:this }
        @channel.unregister myTriggers...
        
    addTrigger: (cmd) ->
        # Do nothing if the user is just editing an existing command.
        return if @triggers[cmd]?

        # Create a simple trigger that looks up a key in @commands
        @triggers[cmd] = trig.buildTrigger  this, cmd, Sauce.Level.User,
            (user, args, sendMessage) -> sendMessage @commands.get cmd

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

        if @commands.data[args[0]]? or @triggers[cmd]?
            @commands.remove args[0]
            @delTrigger      args[0]
            return sendMessage "Command unset: #{cmd}"
        

    # !set <command> <message>  - Set command
    # !set <command>            - Unset command
    cmdSet: (user, args, sendMessage) ->
        unless args[0]?
            return sendMessage "Usage: !set (name) (message).  !set (name) or !unset (name) to forget a command."

        # !set <command>
        if (args.length is 1)
            return @cmdUnset user, args, sendMessage

        cmd = args.splice 0, 1
        msg = args.join ' '

        @commands.add cmd, msg
        @addTrigger   cmd

        return sendMessage "Command set: #{cmd}"

    handle: (user, command, args, sendMessage) ->
        

exports.New = (channel) ->
    new Commands channel
    
