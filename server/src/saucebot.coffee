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

# Load users from the database
io.debug 'Loading users...'
users.load (userlist) ->
    io.debug "Loaded #{(Object.keys userlist).length} users."

# Load channels from the database
io.debug 'Loading channels...'
chans.load (chanlist) ->
    io.debug "Loaded #{(Object.keys chanlist).length} channels."


class SauceBot
    constructor: (@socket) ->
        @socket.on 'data', (rawdatas) =>
            return unless rawdatas

            rawdata = rawdatas.split "\n"
            for raw in rawdata
                continue unless raw

                try
                    @handle JSON.parse(raw)
                catch error
                    @sendError "Syntax error: #{error}"

    handle: (json) ->
        chan      = json.chan

        # Normalize json.op
        json.op   = if json.op then 1 else null

        # Split the arguments by space
        json.args = json.args.split ' '

        # Handle the message
        chans.handle chan, json, (data) =>
            @say chan, "#{io.noise()} #{data}"
        , =>
            

    sendError: (message) ->
        json = JSON.stringify
                error: 1,
                msg  : message

        io.say '>> '.red + message
        socket.write "#{json}\n"


    say: (channel, message) ->
        send 'say', channel, message

    send: (action, channel, message) ->
        json = JSON.stringify
                act : action
                chan: channel
                msg : message

        io.say '>> '.magenta + "#{action} #{channel}: #{message}"
        @socket.write "#{json}\n"

