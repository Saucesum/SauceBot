# SauceBot user data

Sauce = require './sauce'

db    = require './saucedb'
io    = require './ioutil'

# User list - indexed by username
users = {}

# Name list for quick userid -> username lookup
names = {}

class User
    constructor: (data) ->
        @id     = data.userid
        @name   = data.username
        @global = data.global
        
        @mod = {}
    
    
    isGlobal: ->
        @global is 1
        
    setMod: (chan, level) ->
        @mod[chan] = level
        
    isMod: (chan, level) ->
        level ?= Sauce.Level.Mod
        
        @isGlobal() or @mod[chan] >= level


# Returns a user by their username in lowercase
exports.getByName = (name) ->
    users[name]
    

# Returns a user by their UserID
exports.getById = (id) ->
    getByName names[id]


# Populates the user list
exports.load = (callback) ->
    
    # Clear user list
    users = {}
    names = {}
    
    db.getDataEach 'users', (u) ->
        {userid, username, global} = u
        
        username = username.toLowerCase()
        
        user = new User u
        users[username] = user
        names[userid]   = username
    , ->
        updateModLevels callback
        
        
updateModLevels = (callback) ->
    db.getDataEach 'moderator', (m) ->
        user = users[names[m.userid]]
        user.setMod m.chanid, m.level
    , ->
        callback users if callback
         
