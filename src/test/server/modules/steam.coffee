# Steam module unit test

Sauce = require '../../../server/sauce'
{CheckBot, test} = require '../../saucetest'

Steam = require '../../../server/modules/steam'

module = 'Steam'
describe module, ->
    game = 'Borderlands 2'
    command = "!steam news #{game}"
    describe command, ->
        it "should respond with #{game} news", (done) ->
            test.channel { modules: ['Steam'], strings: Steam.strings }, (channel) ->
                test.command({
                    channel : channel
                    user    : test.user 'Joe_User', Sauce.Level.User
                },
                command,
                new CheckBot().say CheckBot.regex 'message',
                    new RegExp(channel.getString(module, 'steam-news-item',
                        game,
                        channel.getString(module, 'steam-date-format', '\\d+', '\\d+', '\\d+'),
                        '.*'
                    ), 'i')
                )(done)
