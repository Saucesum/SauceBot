assert = require 'assert'
should = require 'should'


# mock config
config = {
    name: 'SauceBot'
}

# TODO: Test SauceBot features

describe 'SauceBot', ->
    describe '#getName()', ->
        it 'should be equal to the config name', ->
            'SauceBot'.should.equal config.name

