# Steam module unit test

Sauce = require '../../../server/sauce'
{CheckBot, test} = require '../../saucetest'

Steam = require '../../../server/modules/steam'

describe 'Steam', ->
    test.channel { modules: ['Steam'] }, (channel) ->
        console.log channel
        game = 'Borderlands 2'
        command = "!steam news #{game}"
        describe command, ->
            it "should respond with #{game} news",
                test.command {
                    channel : channel
                    user    : test.user 'Joe_User', Sauce.Level.User
                }, command,
                new CheckBot().say CheckBot.regex 'message',
                    new RegExp(channel.getString('news-item',
                        game,
                        channel.getString('date-format', '\\d+', '\\d+', '\\d+'),
                        '.*'
                    ), 'i')
