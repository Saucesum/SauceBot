# SauceBot Utility

color = require 'colors'
util  = require 'util'
sbut  = require './util'

LOGGER  = null
LEVEL   = 0

exports.Level = Level = {
    # All messages are shown
    All    : 0
    # Only messages with debug or higher are shown
    Debug  : 1
    # Only messages with verbose or higher are shown
    Verbose: 2
    # Only the normal messages are shown
    Normal : 3
    # Only errors are shown
    Error  : 4
    # No messages are shown
    None   : 5
}

# Sets the logger object. null for no logging.
exports.setLogger = (logger) -> LOGGER = logger

# Sets the logger level. "level" must be in exports.Level
exports.setLevel  = (level ) -> LEVEL  = level

log = (level, tag, message) ->
    if level >= LEVEL
        util.log ('[' + tag + '] ').bold + message

    if LOGGER?
        LOGGER.timestamp level, tag?.stripColors, message?.stripColors


# Logs a message
exports.say = (chan, message) ->
    log(Level.Normal, '#' + chan.blue, message)


# Logs a debug message
exports.debug = (message) ->
    log(Level.Debug, 'DEBUG'.green, message.green)


# Logs a module-info message
exports.module = (message) ->
    log(Level.Verbose, 'MODULE'.blue, message.blue)


# Logs a socket-related message
exports.socket = (message) ->
    log(Level.Normal, 'SOCKET'.cyan, message.cyan)


# Logs an error message
exports.error = (message) ->
    log(Level.Error, 'ERROR', (sbut.getPrevStack().underline + "\t" + message).red.inverse)


exports.irc = (chan, user, message) ->
    userStr = user[hashRand user, cols]
    log(Level.Normal, '#' + chan.blue, userStr + ": " + message)


# HashCode
String.prototype.hashCode = ->
    hash = 0
    if this.length is 0 then return hash
    for i in [0..(this.length - 1)]
        char = this.charCodeAt i
        hash = ((hash<<5)-hash)+ char
        hash = hash & hash
    hash


cols = [
    'red', 'blue', 'green', 'yellow', 'cyan', 'grey', 'magenta', 'black'
]


hashRand = (str, list) ->
    list[Math.abs(str.hashCode() % list.length)]


# Noise characters
chars = [',', '-', '_', '!', '>', '<', '#', '\'', '?', '~']
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
    ~~ (Math.random() * arr.length)
