# Steam module unit test

assert = require 'assert'
should = require 'should'

Sauce = require '../../../server/sauce'
{CheckBot, test} = require '../../saucetest'

Steam = require '../../../server/modules/steam'

describe 'Steam', ->
    test.channel { modules: ['Steam'] }, (channel) ->
        channel.modules[0].should.equal 'Steam'
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
