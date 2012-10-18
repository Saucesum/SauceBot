assert = require 'assert'
should = require 'should'

describe 'Faulty', ->
    describe 'errors', ->
        it 'should kill this test', ->
            0.should.equal 1 # in a world... where everything is possible
