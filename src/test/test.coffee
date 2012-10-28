# Base test file that runs all other tests

assert = require 'assert'
should = require 'should'

fs     = require 'fs'
walk   = require 'walk'

# sauce  = require './saucetest'

# Simple test to make sure the testing framework works
describe 'Array', ->
    describe '#indexOf()', ->
        it 'should return -1 when the value is not present', ->
            [1,2,3].indexOf(5).should.equal -1
            [1,2,3].indexOf(0).should.equal -1

b = undefined
before (done) -> require('request') 'http://www.google.com', (err, resp, body) ->
    b = body
    done()
describe 'Test', ->
    describe 'Test_', ->
        describe 'Test__', ->
            it 'should be defined', -> assert b
