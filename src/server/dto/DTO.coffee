# SauceBot Data Transfer Object


db = require '../saucedb'
io = require '../ioutil'

# Data Transfer Object abstract base class
# All methods of a DTO should immediately reflect any changes made to their
# dataset to the database.
class DTO
    constructor: (@channel, @table) ->
        # Constructs the DTO
        
    load: ->
        # Loads data from the database
        
    add: (item) ->
        # Adds item to the dataset
        
    remove: (item) ->
        # Removes item from the dataset
        
    clear: ->
        # Clears all items from the dataset
        
    set: (items) ->
        # Set dataset items
        
    get: ->
        # Returns the underlying dataset
        
        
exports.DTO = DTO