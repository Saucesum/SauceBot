# SauceBot Session Manager

{Session}  = require './sauce'

fs         = require 'fs'
parser     = require 'groan'


# Cookie format regex
COOKIE = /^[a-zA-Z0-9]+$/

isValidCookie = (cookie) ->
    COOKIE.test cookie
    

getSessionFile = (cookie) ->
    Session.Dir + Session.Prefix + cookie
    

getSession = (cookie) ->
    return unless isValidCookie cookie
    
    path = getSessionFile cookie
    
    if data = fs.readFileSync path then parser data.toString 'utf8'


# Fetches the userid associated with the specified PHP cookie.
# Returns null/undefined on error.
exports.getUserID = (cookie) ->
    session = getSession cookie
    if session then session.userid else null
    
