# SauceBot IRC Client

irc   = require 'irc'
net   = require 'net'
color = require 'colors'

io    = require './ioutil'

[node, filename, servname, username, password] = process.argv

unless (password)
    io.error "usage: #{node} #{filename} <channel> <username> <password>"
    return
  
  

  

bot = new irc.Client "#{servname}.jtvirc.com", username,
      debug: true
      channels: ['#' + servname]
      userName: username
      realName: username
      password: password
      floodProtection: true
      stripColors    : true
      
      
      
bot.addListener 'error', (message) ->
    io.error "#{message.command}: #{message.args.join ' '}"
      
      
      
bot.addListener 'message', (from, to, message) ->
  return unless to[0] is '#'
  
  chan = to.substring 1 # Strip out the '#'
  
  io.debug "[#{to}] <#{from}> #{message}"
  
  
