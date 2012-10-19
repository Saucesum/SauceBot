# SauceBot testing utilities

# TODO

assert = require 'assert'

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
    
    size: ->
        @tests.length

    @equalsTest: (key, value) ->
        (entry) ->
            entry[key] = value

    @regexTest: (key, pattern) ->
        (entry) ->
            pattern.test entry[key]
    
    check: (type, test) ->
        (entry) ->
            entry.type is type and test entry

    test: (other) ->
        other.log.every (entry, index) -> @tests[index] entry


# A Channel that only performs the minimum functions needed to support a
# module
class TestChannel
    
    constructor: (@name, @bot) ->
        @modules = []
        @triggers = []
        @vars = new TestVars @
    
    register: (args...) ->
        switch args.length
            when 1
                [trigger] = args
            when 4
                trigger = trig.buildTrigger args...
            else
                false

        index = 0
        for t in @triggers
            index++ if trigger.priority >= t.priority
        @triggers.splice index, 0, trigger
        
        true
    
    listTriggers: (restrictions = {}) ->
        results = @triggers
        for attr, value of restrictions
            results = (elem for elem in results when (elem[attr] is value))
        results
    
    unregister: (triggersToRemove...) ->
        @triggers = (elem for elem in @triggers when not (elem in triggersToRemove))
    
    addModule: (module) ->
        @modules.push module
        module.load()
    
    testMessage: (message, user) ->
        for trigger in @triggers
            if trigger.test(msg) and user.op >= trigger.oplevel
                args = trigger.getArgs msg
                trigger.execute user, args, bot
                break
        
        for module in @modules
            module.handle user, msg, bot


# A wrapper for Vars that intercepts any variable values and stores them in a
# log, which can then later be tested
class TestVars
    
    constructor: (@channel) ->
        @log = []
        @vars = new Vars @channel
    
    register: (cmd, handler) ->
        @vars.register cmd, (user, args, cb) =>
            handler user, args, (result) =>
                @log.push {
                    variable : cmd
                    args     : args
                    result   : result
                }
                cb result
        
    unregister: (cmd, handler) ->
        @vars.unregister cmd, handler
    
    parse: (user, message, raw, cb) ->
        @vars.parse user, message, raw, cb

    strip: (message) ->
        @vars.strip message
    
    test: (variable, args, test) ->
        (entry.result for entry in @log if entry.variable is variable and
            entry.args.every (e, i) -> e = args[i]
        ).every (result, i) -> test result


user: (name, level) ->
    {
        name : name
        op   : level 
    }


# Returns a function that can be passed to "it(...)" for unit testing commands
#
# * module: the "New" constructor of the module to load for testing
# * command: the command to submit to the test framework
# * expected: a TestBot instance that will determine if the result is correct
# = the callback to be used for testing
testCommand: (module, command, user, expected) ->
    (done) ->
        bot = new TestBot ->
            assert expected.test bot
            done()
        , expected.size
        channel = new TestChannel 'Test Channel', bot
        channel.addModule module channel
        channel.testMessage command, user



# Returns a function that can be passed to "it(...)" for unit testing variables
#
# * module: the "New" constructor of the module to load for testing
# * variable: the name of the variable to test
# * args: the arguments to pass to the variable
# * user: the user object to test the variable with
# * test: a function that returns whether the result of the variable is correct
# = the callback to be used for testing
testVariable: (module, variable, args, user, test) ->
    (done) ->
        bot = new TestBot ->
        channel = new TestChannel 'Test Channel', bot
        channel.addModule module channel
        channel.vars.vars.handlers[variable] user, args, (result) ->
            assert test result
            done()


###
Sauce = require '../../server/sauce'
Base = require '../../server/modules/base' 
it('"!calc 2 + 2" should be 4',
    testCommand Base.New, '!calc 2 + 2', user('ravn_tm', Sauce.Level.Admin),
        new CheckBot().say CheckBot.equalsTest 'message', '=4'
)
###
