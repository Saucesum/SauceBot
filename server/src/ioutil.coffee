# SauceBot Utility

color = require 'colors'

DEBUG   = true
VERBOSE = true

exports.setDebug   = (state) -> DEBUG   = state
exports.setVerbose = (state) -> VERBOSE = state

exports.say = (message) ->
    console.log message.bold

exports.debug = (message) ->
    console.log ('[DEBUG] '.bold + message).green

exports.module = (message) ->
    console.log ('[MODULE] '.bold + message).blue

exports.error = (message) ->
    console.log ('[ERROR] '.bold + message).red.inverse

# Anti-ban utilities
start = ['{', '<', '[', '(']
end   = ['}', '>', ']', ')']

chars = ['!', '>', '<', '?', '#', '%', '&', '+', '-', '_', '\'', '"', '|']

exports.infix = (message) ->
    idx = randIdx start
    start[idx] + message + end[idx]

exports.noise = ->
    chars[randIdx chars]

randIdx = (arr) ->
    Math.floor (Math.random() * arr.length)

# Utility
exports.now = ->
    new Date().getTime() / 1000

