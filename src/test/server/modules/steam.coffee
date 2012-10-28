# Steam module unit test

assert = require 'assert'
should = require 'should'

Sauce            = require '../../../server/sauce'
{Check, test} = require '../../saucetest'
{ModuleTest}     = require './test' 

Steam = require '../../../server/modules/steam'

###
module = 'Steam'
describe module, ->
    game = 'Borderlands 2'
    command = "!steam news #{game}"
    describe command, ->
        it "should respond with #{game} news", (done) ->
            test.channel { modules: [module] }, (channel) ->
                test.command({
                    channel : channel
                    user    : test.user 'Joe_User', Sauce.Level.User
                },
                command,
                new CheckBot().say Check.regex 'message',
                    new RegExp(channel.getString(module, 'steam-news-item',
                        game,
                        channel.getString(module, 'steam-date-format', '\\d+', '\\d+', '\\d+'),
                        '.*'
                    ), 'i')
                )(done)
###

steam = new ModuleTest 'Steam'
game = 'Borderlands 2'
steam.addCommand {
    commands    : ["!steam news #{game}"]
    description : 'should respond with #{game} news'
    expected    : new Check [{
        say: Check.regex new RegExp(
            # TODO: Figure out how to access channel strings from here
        )
    }]
}
