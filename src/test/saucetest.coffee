# SauceBot testing utilities

# Test libraries
assert = require 'assert'
should = require 'should'

# SauceBot
db        = require '../server/saucedb'
{Channel} = require '../server/channels'


# A fake Bot that simply logs any calls to it for future analysis
class TestBot
    
    constructor:(@callback, @size = 1) ->
        @log = []
    
    say: (message) ->
        @push { type : 'say', message : message }
    ban: (user) ->
        @push { type : 'ban', user : user }
    unban: (user) ->
        @push { type : 'unban', user : user }
    clear: (user) ->
        @push { type : 'clear', user : user }
    timeout: (user, length) ->
        @push { type : 'timeout', user : user, time : length }
    commercial: ->
        @push { type : 'commercial' }
    
    push: (entry) ->
        @log.push entry
        @callback() if @log.length == @size


# A "Bot" that creates a pattern that can be used to test whether a "TestBot"
# matches it
class CheckBot
    
    constructor: ->
        @tests = []
    
    say: (test) ->
        @tests.push check 'say', test
        @
    ban: (test) ->
        @tests.push check 'ban', test
        @
    unban: (test) ->
        @tests.push check 'unban', test
        @
    clear: (test) ->
        @tests.push check 'clear', test
        @
    timeout: (test) ->
        @tests.push check 'timeout', test
        @
    commercial: ->
        @tests.push check 'commercial', -> true
        @

    @equals: (key, value) ->
        (entry) ->
            entry[key] = value

    @regex: (key, pattern) ->
        (entry) ->
            pattern.test entry[key]
    
    check: (type, test) ->
        (entry) ->
            entry.type is type and test entry
    
    size: ->
        @tests.length

    test: (other) ->
        other.log.every (entry, index) -> @tests[index] entry


# Object for test utility methods.
exports.test = test = {

    # Creates a user object.
    #
    # * name: the username
    # * level: the permsissions level
    user: (name, level) -> { name: name, op: level }


    # Creates a new channel and populates the database (used for testing).
    #
    # * options: the parameters for creating this channel; valid options are:
    #      * chanid  : the fake ID of the channel, default 0
    #      * name    : the name to use for the channel, default 'Test'
    #      * bot     : the name of the bot for the channel, default 'TestBot'
    #      * modonly : whether the channel is in mod-only mode, default 0
    #      * quiet   : whether the channel is in quiet mode, default 0
    #      * strings : any localization strings to include with the channel
    #      * modules : any modules to load with this channel
    channel: (options) ->
        defaultOpts = {
            chanid  : 0
            name    : 'Test'
            bot     : 'TestBot'
            modonly : 0
            quiet   : 0
            strings : {}
            modules : []
        }

        for k, v of defaultOpts
            options[k] ?= v

        {chanid, name, bot} = options

        db.addData 'channel', ['chanid', 'name', 'status', 'bot'], [{
            chanid : chanid
            name   : name
            status : 1
            bot    : bot
        }]

        {modonly, quiet} = options
    
        db.addData 'channelconfig', ['chanid', 'modonly', 'quiet'], [{
            chanid  : chanid
            modonly : modonly
            quiet   : quiet
        }]

        {strings} = options
        
        db.addData 'strings', ['key', 'value'], ({
            key   : key
            value : value
        } for key, value of strings)

        {modules} = options
        
        db.addData 'module', ['chanid', 'module', 'state'], [{
            chanid : chanid
            module : module
            state  : 1
        }] for module in modules
    
        return new Channel {
            chanid : chanid
            name   : name
            status : 1
            bot    : bot
        }
    
    
    # Returns a function that can be passed to "it(...)" for unit testing commands
    #
    # * context: an object containing "channel", the channel to test the command
    #            in, and "user", the user to test the command as 
    # * command: the command to submit to the test framework
    # * expected: a CheckBot instance that will determine if the result is correct
    # = the callback to be used for testing
    ommand: (context, command, expected) ->
        (done) ->
            bot = new TestBot ->
                assert expected.test bot
                done()
            , expected.size
            
            context.channel.handle {
                user : context.user.name
                op   : context.user.level
                msg  : command
            }, bot
    
    
    # Returns a function that can be passed to "it(...)" for unit testing variables
    #
    # * context: an object containing "channel", the channel to test the variable
    #            in, and "user", the user to test the variable as
    # * variable: the name of the variable to test
    # * args: the arguments to pass to the variable
    # * condition: a function that returns whether the result of the variable is correct
    # = the callback to be used for testing
    variable: (context, variable, args, condition) ->
        (done) ->
            bot = new TestBot ->
            context.channel.vars.handlers[variable] context.user, args, (result) ->
                assert condition result
                done()

}
    
### EXAMPLE
context = { 
    channel: testChannel { modules: ['Base'] }
    user: user 'ravn_tm', Sauce.Level.Admin
}
it('should say "=4"', testCommand context, '!calc 2+2', new CheckBot().say CheckBot.equals 'message', '=4')
it('should be a number', testVariable context, 'rand', ['1', '10'], (result) -> /\d+/.test result)
###

exports.CheckBot = CheckBot
