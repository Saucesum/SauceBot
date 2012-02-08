# SauceBot IRC Client

irc = require 'irc'

io  = require './ioutil'


class SauceIRC
    
    constructor: (@server, @username, @password, @onError, @onMessage) ->
        
        @channel = '#' + @server;
        
        @connect()
        @bot.addListener 'error',              @onError
        @bot.addListener 'message' + @channel, @onMessage
        

    connect: ->
        @bot = new irc.Client "#{@server}.jtvirc.com", @username,
              debug: true
              channels: [@channel]
              userName: @username
              realName: @username
              password: @password
              floodProtection: true
              stripColors    : true
              
    say: (message) ->
        @bot.say @channel, message 

exports.setup = (server, username, password, onError, onMessage) ->
    new SauceIRC server, username, password, onError, onMessage
