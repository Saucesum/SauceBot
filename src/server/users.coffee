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
    
    
    # Returns whether the user is a global administrator
    isGlobal: ->
        @global is 1
        
    # Sets the user's mod-level in the specified channel
    setMod: (chanid, level) ->
        @mod[chanid] = level
        
    # Returns whether the user is a mod in the specified channel
    isMod: (chanid, level) ->
        level ?= Sauce.Level.Mod
        
        @isGlobal() or @mod[chanid] >= level
        
    getMod: (chanid) ->
        if @isGlobal() then Sauce.Level.Owner + 1 else @mod[chanid]


# Returns a user by their username in lowercase
exports.getByName = (name) ->
    users[name]
    

# Returns a user by their UserID
exports.getById = (id) ->
    exports.getByName names[id]


# Populates the user list
exports.load = (callback) ->
    
    # Clear user list
    users = {}
    names = {}
    
    db.getDataEach 'users', (u) ->
        {userid, username, global} = u
        
        username = username.toLowerCase()
        
        user = new User u
        
        # Add user to caches
        users[username] = user
        names[userid]   = username
    , ->
        updatePermissions callback
        
        
# Updates user permissions
updatePermissions = (callback) ->
    
    # Clear user permissions
    user.mod = {} for user in users
    
    db.getDataEach 'moderator', (m) ->
        {userid, chanid, level} = m
        
        user = users[names[userid]]
        
        # Update the user's permissions
        user.setMod chanid, level
    , ->
        callback users if callback
         
