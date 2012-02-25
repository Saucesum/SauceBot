# SauceBot Module: Hangman

Sauce = require '../sauce'
db    = require '../saucedb'

io    = require '../ioutil'

fs    = require 'fs'

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
#  !hm top
#  !hm new [language]
#  !hm stop
#  !hm <word>
#  !hm <character>
#
class Hangman
    constructor: (@channel) ->
        
        # TODO: Allow for different wordlists depending on channel
        @language = 'english'

        
    load: (chan) ->
        @channel = chan if chan?
        
        loadWordList @language unless wordListLoaded @language


    handle: (user, command, args, bot) ->
        @word = randomWord @language
        bot.say @word
        
        
randomWord = (listname) ->
    list = wordList listname
    list[randIdx list]


randIdx = (arr) ->
    Math.floor (Math.random() * arr.length)


wordList = (list) ->
    if wordListLoaded list
        wordlists[list]
    else
        wordlists[list] = []


wordListLoaded = (list) ->
    wordlists[list]?


loadWordList = (listname) ->
    fs.readFile wordfiles[listname], 'utf8', (err, data) ->
        throw err if err?
        
        list = wordList listname
        
        for word in data.split '\n'
            list.push word if word.length > 5
            
        io.module "[HM] Loaded #{listname} - #{list.length} words"



exports.New = (channel) ->
    new Hangman channel
