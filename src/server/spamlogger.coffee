# SauceBot spam logger for Twitch administrators

Sauce = require './sauce'
db    = require './saucedb'
io    = require './ioutil'

# Constants
SPAM_LIST_TABLE = 'spamlist'
SPAM_TABLE      = 'spam'

# Spam lists 
lists = []

# (Re)loads the spam list data
loadLists = ->
    db.getData SPAM_LIST_TABLE, (data) ->
        newLists = []
        for listData in data
            newLists.push new SpamList listData.id, listData.link

        lists = newLists

# Logs the spam message to the database
logSpam = (id, channel, user, message) ->
    data = [id, ~~(Date.now()/1000), channel, user, message]
    db.addData SPAM_TABLE, ['list', 'time', 'channel', 'user', 'message'], [data]

# Executes the spam list tests for the input message
runTests = (channel, user, message) ->
    list.run(channel, user, message) for list in lists


class SpamList
    constructor: (@id, @link) ->
    
    run: (channel, user, message) ->
        if message?.indexOf(@link) >= 0
            logSpam @id, channel, user, message
            

exports.reload = loadLists
exports.run    = runTests

