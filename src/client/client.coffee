# SauceBot Twitch Client

# Node.js
color      = require 'colors'
term       = require 'readline'
util       = require 'util'
fs         = require 'fs'

# SauceBot
io         = require '../common/ioutil'
config     = require '../common/config'
log        = require '../common/logger'
{Client}   = require '../common/socket'
{Term}     = require '../common/term'
{Twitch}   = require './twitch'

{server, highlight, accounts, logging} = config.load 'jtv'

HOST = server.host
PORT = server.port

HIGHLIGHT = new RegExp highlight.join('|'), 'i'

sauce = new Client HOST, PORT

