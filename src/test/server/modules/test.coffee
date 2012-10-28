Sauce     = require '../../../server/sauce'
SauceTest = require('../../saucetest').test
{MODULES} = require '../../../server/module' 

DEFAULT_USER = SauceTest.user 'TestUser', Sauce.Level.Global

class ModuleTest
    constructor: (@module) ->
        @tests = []
        0xCAFED00D # For the more masculine of us (moustaches don't count)
    
    addCommand: (options) ->
        @tests.push ({
            type        : 'command'
            commands    : options.commands
            description : options.description ? ''
            user        : options.user ? DEFAULT_USER
            expected    : options.expected
        })
    
    addVariable: (options) ->
        @tests.push ({
            type        : 'variable'
            variable    : options.variable
            description : options.description ? ''
            user        : options.user ? DEFAULT_USER
            arguments   : options.arguments
            condition   : options.condition
        })
        
    test: (channelOptions) ->
        channel = undefined
        channelOptions.modules.push @module unless channelOptions.modules.indexOf @module != -1
        before (done) ->
            SauceTest.channel channelOptions, (chan) ->
                channel = chan
                done()
        
        describe @module, ->
            switch test.type
                when 'command'
                    describe "[Command(s)] '#{test.commands.join ', '}'", ->
                        it test.description, (done) ->
                            bot = new TestBot ->
                                expected.test bot
                                done()
                            , expected.size()
                            channel.handle {
                                user : test.user.name,
                                op   : test.user.op,
                                msg  : test.command
                            } for command in test.commands
                
                when 'variable'
                    describe "[Variable] '#{test.variable}'", ->
                        it test.description, (done) ->
                            bot = new TestBot ->
                            channel.vars.handlers[test.variable] test.user, test.arguments, (result) ->
                                test.condition result
                    
        after (done) ->
            # TODO: Delete all database data for the test channel

exports.ModuleTest = ModuleTest
