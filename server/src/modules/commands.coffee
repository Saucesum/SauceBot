# SauceBot Module: Commands

Sauce = require '../sauce'
db    = require '../saucedb'

io    = require '../ioutil'

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
        @commands = {}
        
    load: (chan) ->
        @channel = chan if chan?
        
        # Load custom commands
        db.loadData @channel.id, 'commands',
                key  : 'cmdtrigger',
                value: 'message',
                (commands) =>
                    @commands = commands
                    io.module "[Commands] Loaded commands for #{@channel.id}: #{@channel.name}"

    unsetCommand: (command) ->
        delete @commands[command]
        db.removeChanData @channel.id, 'commands', 'cmdtrigger', command
        
    setCommand: (command, message) ->
        @commands[command] = message
        db.addChanData @channel.id, 'commands',
                ['cmdtrigger', 'message'],
                [[command, message]]

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
            res = @commands[command]

        sendMessage res if res?

exports.New = (channel) ->
    new Commands channel
    
