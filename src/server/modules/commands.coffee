# SauceBot Module: Commands

Sauce = require '../sauce'
db    = require '../saucedb'
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
        
    load: ->
        # Load custom commands
        @commands.load()
        
        
    unsetCommand: (command) ->
        @commands.remove command
        
        
    setCommand: (command, message) ->
        @commands.add command, message
        

    handle: (user, command, args, sendMessage) ->
        {op} = user
        res  = undefined
        
        if (op? and (command in ['set', 'unset']))
            
            # !(un)?set <command> - Unset command
            if (args.length is 1)
                cmd = args[0]
                
                @unsetCommand cmd
                res = "Command unset: #{cmd}"
                
            # !(un)?set <command> <message> - Set message
            else if (args.length > 1)
                cmd = args.splice 0, 1
                msg = args.join ' '
                
                @setCommand cmd, msg
                res = "Command set: #{cmd}"
                
        else
            res = @commands.get command
            if res? then res = vars.parse res

        sendMessage res if res?

exports.New = (channel) ->
    new Commands channel
    
