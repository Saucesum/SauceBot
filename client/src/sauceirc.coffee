# SauceBot IRC Client

irc = require 'irc'

io  = require './ioutil'


class SauceIRC
    
    constructor: (@server, @username, @password) ->
        @connect()
        
        @bot.addListener 'error',              @onError
        @bot.addListener 'message#' + @server, @onMessage
        
        

    connect: ->
        @bot = new irc.Client "#{@server}.jtvirc.com", @username,
              debug: true
              channels: ['#' + @server]
              userName: @username
              realName: @username
              password: @password
              floodProtection: true
              stripColors    : true
              
              
    onError: (message) ->
        {command, args} = message
        
        io.error "#{command}: #{args.join ' '}"
              
              
    onMessage: (from, message) ->
        io.debug "<#{from}> #{message}"


exports.setup = (server, username, password) ->
    new SauceIRC server, username, password
