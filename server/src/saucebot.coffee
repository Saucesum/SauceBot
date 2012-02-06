 ###########################################################
#                                                           #
# - Node.js implementation of the SauceBot Command Server - #
#                                                           #
 ###########################################################

# Config
Sauce = require './sauce'

# Sauce
db    = require './saucedb'
users = require './users'
chans = require './channels'

# Utility
io    = require './ioutil'

# Node.js
net   = require 'net'
url   = require 'url'
color = require 'colors'

io.debug 'Loading users...'
users.load (userlist) ->
    io.debug "Loaded #{(Object.keys userlist).length} users."

io.debug 'Loading channels...'
chans.load (chanlist) ->
    io.debug "Loaded #{(Object.keys chanlist).length} channels."


