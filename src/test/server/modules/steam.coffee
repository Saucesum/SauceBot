# Steam module unit test

Sauce = require '../../../server/sauce'
{CheckBot, test} = require '../../saucetest'

describe 'Steam', ->
    channel = test.channel { modules: ['Steam'] }
    command = '!steam news Borderlands 2'
    describe command, ->
        it 'should respond with Borderlands 2 news',
            test.command {
                channel : channel
                user    : test.user 'Joe_User', Sauce.Level.User
            }, command,
            new CheckBot().say (test) ->
                test.message.toLowerCase().indexOf('borderlands 2') != -1 and
                /News for .*? from \d+\/\d+\/\d+: .*/.test test.message
