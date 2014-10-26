# SauceBot user data

Sauce = require './sauce'

db    = require './saucedb'
io    = require './ioutil'

# The list of all users, indexed by username
users = {}

# A convenience map of user IDs to their respective usernames
names = {}

# A map of channel moderators.
# Structure: { chanId: { userId: userLevel, ... }, ... }
permissions = {}


# A basic data structure for storing the data associated with a single user who
# is registered in the database.
class User
    constructor: (data) ->
        @id     = data.userid
        @name   = data.username
        @global = data.global
    
    
    # Returns whether the user is a global administrator.
    #
    # = whether the user is a global administrator
    isGlobal: ->
        @global is 1

        
    # Returns whether the user is a mod in the specified channel (or if they
    # are a global mod).
    #
    # * chanid: the channel ID that the user is being checked in
    # * level: the minimum moderator level in the channel
    # = whether the user is a mod in the channel
    isMod: (chanid, level) ->
        @getMod(chanid) >= (level ? Sauce.Level.Mod)
    

    # Returns the mod level of the user in the given channel, with global mods
    # being the highest level of moderator.
    #
    # * chanid: the channel ID that the user is being checked in
    # = the mod level of the user in the channel
    getMod: (chanid) ->
        if @isGlobal() then Sauce.Level.Owner + 1 else getMod(chanid, @id)

    #Returns if the user is subbed in the given channel
    #isSub: (chanid) ->
        


# Returns a user by their username in lowercase.
#
# * name: the username to look up
# = the user with the given name, if found
exports.getByName = (name) ->
    users[name]
    

# Returns a user by their UserID
#
# * id: the user id to look up
# = the user with the given id, if found
exports.getById = (id) ->
    exports.getByName names[id]


# Returns the username associated with the specified user id.
# * id: the userid.
# = the username, or undefined if not found.
exports.getName = (id) ->
    names[id]


exports.getNullUser = ->
    return new User {
        userid  : -1
        username: 'N/A'
        global  : 0
    }


# Returns the moderators of the specified channel.
# * chanid: The id of the channel to look up.
# = a map of user id to mod level.
exports.getMods = (chanid) ->
    return permissions[chanid] ? {}


# Returns the moderator level of the specified user in the specified channel.
# * chanid: The channel.
# * userid: The user.
# = The moderator level.
exports.getMod = getMod = (chanid, userid) ->
    return permissions[chanid]?[userid] ? 0


# Populates the user list from the database, calling a given function once the
# data has been loaded.
#
# * callback: the function to call after the data loads, which takes the list
#             of users, indexed by name, as an argument
exports.load = (callback) ->
    
    # Clear user list
    users = {}
    names = {}
    
    # First load the user local data
    db.getDataEach 'users', (u) ->
        {userid, username, global} = u
        
        username = username.toLowerCase()
        
        user = new User u
        
        # Add user to caches
        users[username] = user
        names[userid]   = username
    , ->
        # Now we have to load the channel specific permissions of each user
        # before running the callback
        updatePermissions callback
        
        
# Updates user permissions in any channels after the users list has been populated.
#
# * callback: the function to call after the data loads, which takes the list
#             of users, indexed by name, as an argument
updatePermissions = (callback) ->
    
    # Clear user permissions
    permissions = {}
    
    db.getDataEach 'moderator', (m) ->
        {userid, chanid, level} = m
        
        # Update the permissions map
        unless permissions[chanid]?
            permissions[chanid] = {}

        permissions[chanid][userid] = level
    , ->
        callback users if callback
         
