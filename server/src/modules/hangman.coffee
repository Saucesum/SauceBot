# SauceBot Module: Hangman

Sauce = require '../sauce'
db    = require '../saucedb'

io    = require '../ioutil'

# Module description
exports.name        = 'Hangman'
exports.version     = '1.0'
exports.description = 'Who doesn\'t like hangman?!'

io.module '[HM] Init'

# Language dictionaries
wordfiles =
    'english'  : '/usr/share/dict/british-english'
    'american' : '/usr/share/dict/american-english'
    'norwegian': '/usr/share/dict/norsk'
    
    
wordlists = {}

# Hangman module
# - Handles:
#  !hm
#  !hm new
#  !hm stop
#  !hm <word>
#  !hm <character>
#
class Hangman
    constructor: (@channel) ->
        
        
    load: (chan) ->
        @channel = chan if chan?
        

    handle: (user, command, args, sendMessage) ->
        
        

wordList = (list) ->
    wordlists[list]


wordListLoaded = (list) ->
    wordlists[list]?


loadWordList = (list) ->


exports.New = (channel) ->
    new Hangman channel
