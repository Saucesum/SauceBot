# SauceBot Utility

color = require 'colors'
util  = require 'util'


DEBUG   = true
VERBOSE = true

exports.setDebug   = (state) -> DEBUG   = state
exports.setVerbose = (state) -> VERBOSE = state

# Returns the current stack trace's last location
getPrevStack = ->
    # I almost added a semicolon here due to its ugliness. :D
    line = new Error().stack.split("\n")[3].trim()
    line.substring(line.indexOf('bin/') + 4).replace(')', '')

# Logs a message
exports.say = (message) ->
    console.log message.bold

# Logs a debug message
exports.debug = (message) ->
    util.log ('[DEBUG] '.bold + message).green if DEBUG

# Logs a module-info message
exports.module = (message) ->
    util.log ('[MODULE] '.bold + message).blue if VERBOSE

# Logs a socket-related message
exports.socket = (message) ->
    util.log ('[SOCKET] '.bold + message).cyan 

# Logs an error message
exports.error = (message) ->
    util.log ('[ERROR] '.bold + getPrevStack().underline + ' ' + message).red.inverse


# Noise characters
chars = ['!', '>', '<', '?', '#', '%', '&', '+', '-', '_', '\'', '"', '|']
start = ['{', '<', '[', '(']
end   = ['}', '>', ']', ')']

# Infixes the message by matching random start and end characters, such as ( ), { } and < >
exports.infix = (message) ->
    idx = randIdx start
    start[idx] + message + end[idx]


# Returns a random "noise"-character
exports.noise = ->
    chars[randIdx chars]


# Returns a random index of the specified array
randIdx = (arr) ->
    Math.floor (Math.random() * arr.length)


# Returns the current time in milliseconds
exports.now = ->
    new Date().getTime() / 1000

