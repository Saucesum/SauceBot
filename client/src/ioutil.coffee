# SauceBot Utility

color = require 'colors'

# Logs a message
exports.say = (message) ->
    console.log message.bold

# Logs a debug message
exports.debug = (message) ->
    console.log ('[DEBUG] '.bold + message).green

# Logs a module-info message
exports.module = (message) ->
    console.log ('[MODULE] '.bold + message).blue

# Logs an error message
exports.error = (message) ->
    console.log ('[ERROR] '.bold + ' ' + message).red.inverse

