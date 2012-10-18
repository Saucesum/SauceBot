assert = require 'assert'
should = require 'should'


# TODO: Test "Base" module's features

testresult = '[Test] Test! Ravn_TM - Global'

describe 'Base', ->
    describe 'command !test', ->
        it 'should do something', ->
            '[Test] Test! Ravn_TM - Global'.should.equal testresult
