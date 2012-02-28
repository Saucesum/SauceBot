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
        @loaded = false
        
        
    load: ->
        @unload()
        @loaded = true
                
        io.module "[Commands] Loading for #{@channel.id}: #{@channel.name}"

        @channel.register  this, "set"  , Sauce.Level.Mod,
            (user,args,bot) =>
                @cmdSet user, args, bot
        @channel.register  this, "unset", Sauce.Level.Mod,
            (user,args,bot) =>
                @cmdUnset user, args, bot

        # Load custom commands
        @commands.load =>
            for cmd of @commands.data
                @addTrigger cmd


    unload:->
        return unless @loaded
        @loaded = false
        
        io.module "[Commands] Unloading from #{@channel.id}: #{@channel.name}"
        myTriggers = @channel.listTriggers { module:this }
        @channel.unregister myTriggers...
        @triggers = {}
        
        
    addTrigger: (cmd) ->
        # Do nothing if the user is just editing an existing command.
        return if @triggers[cmd]?

        # Create a simple trigger that looks up a key in @commands
        @triggers[cmd] = trig.buildTrigger  this, cmd, Sauce.Level.User,
            (user, args, bot) =>
                parsed = vars.parse @channel, user, @commands.get(cmd)
                bot.say parsed

        @channel.register @triggers[cmd]


    delTrigger: (cmd) ->
        # Do nothing if the trigger doesn't exist.
        return unless @triggers[cmd]?

        @channel.unregister @triggers[cmd]

        delete @triggers[cmd]


    # !(un)?set <command>  - Unset command
    cmdUnset: (user, args, bot) ->
        unless args[0]?
            return bot.say "Usage: !unset (name).  Only forgets commands made with !set."

        cmd = args[0]

        if @commands.data[cmd]? or @triggers[cmd]?
            @commands.remove cmd
            @delTrigger      cmd
            return bot.say "Command unset: #{cmd}"
        

    # !set <command> <message>  - Set command
    # !set <command>            - Unset command
    cmdSet: (user, args, bot) ->
        unless args[0]?
            return bot.say "Usage: !set (name) (message).  !set (name) or !unset (name) to forget a command."

        # !set <command>
        if (args.length is 1)
            return @cmdUnset user, args, bot

        cmd = (args.splice 0, 1)[0]
        msg = args.join ' '

        @commands.add cmd, msg
        @addTrigger   cmd

        return bot.say "Command set: #{cmd}"


    handle: (user, msg, bot) ->



exports.New = (channel) ->
    new Commands channel
    
