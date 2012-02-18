# SauceBot Data Transfer Object


db = require '../saucedb'
io = require '../ioutil'

# Data Transfer Object abstract base class
class DTO
    constructor: (@channel, @table) ->
        # Constructs the DTO
        
    load: ->
        # Loads data from the database
        
    add: (item) ->
        # Adds item to the database
        
    remove: (item) ->
        # Removes item from the database
        
    clear: ->
        # Clears all items from the database
        
    set: (items) ->
        # Set database items
        
    get: ->
        # Returns the underlying dataset
        
        
exports.DTO = DTO