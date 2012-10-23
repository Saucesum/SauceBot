# Steam module unit test

Sauce = require '../../../server/sauce'
{CheckBot, test} = require '../../saucetest'

Steam = require '../../../server/modules/steam'

describe 'Steam', ->
    channel = test.channel { modules: ['Steam'] }
    game = 'Borderlands 2'
    command = "!steam news #{game}"
    describe command, ->
        it "should respond with #{game} news",
            test.command {
                channel : channel
                user    : test.user 'Joe_User', Sauce.Level.User
            }, command,
            new CheckBot().say CheckBot.regex 'message',
                new RegExp(channel.str('news-item',
                    game,
                    channel.str('date-format', '\\d+', '\\d+', '\\d+'),
                    '.*'
                ), 'i')
