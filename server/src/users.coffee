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
        level = Sauce.Level.Mod unless level?
        
        @isGlobal() or @mod[chan] >= level
