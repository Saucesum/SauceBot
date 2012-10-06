# SauceBot Module: Hangman

Sauce = require '../sauce'
db    = require '../saucedb'

io    = require '../ioutil'

fs    = require 'fs'

# Module description
exports.name        = 'Hangman'
exports.version     = '1.0'
exports.description = 'Who doesn\'t like hangman?!'

# Module strings
exports.strings = {
    "test-random-word": "Random word: @1@"
}

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
        
        @channel.register  this, "hm", Sauce.Level.User,
            (user,args,bot) =>
                @word = randomWord @language
                @word2 = randomWord @language
                bot.say @str('test-random-word', @word, @word2)
                
        @channel.vars.register 'hm', (user, args, cb) =>
            cb @word
            
    unload: ->
        @channel.vars.unregister 'hm'
        
        io.module "[Hangman] Unloading from #{@channel.id}: #{@channel.name}"
        myTriggers = @channel.listTriggers { module:this }
        @channel.unregister myTriggers...
        


    handle: (user, msg, bot) ->
        
        
randomWord = (listname) ->
    list = wordList listname
    list[randIdx list]


randIdx = (arr) ->
    ~~ (Math.random() * arr.length)


wordList = (list) ->
    if wordlists[list]?
        wordlists[list]
    else
        wordlists[list] = []


wordListLoaded = (list) ->
    wordlists[list]?


loadWordList = (listname) ->
    fs.readFile wordfiles[listname], 'utf8', (err, data) ->
        throw err if err?

        return if wordlists[listname]?        
        
        list = wordList listname
        
        for word in data.split '\n'
            list.push word if word.length > 5 and /^[a-zA-Z]+$/.test word
            
        io.module "[HM] Loaded #{listname} - #{list.length} words"
        wordlists[listname] = list


exports.New = (channel) ->
    new Hangman channel
