assert = require 'assert'
should = require 'should'

# Choose your universe wisely

describe 'Faulty', ->
    describe 'errors', ->
        it 'should kill this test', ->
            1.should.equal 1 # in a world... where everything is possible
