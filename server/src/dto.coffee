# SauceBot Data Transfer Object
#
# TODO:
#  - load array
#  - load hash
#  - load single-row table
#  - add item
#  - remove item
#  - clear items
#  - set items
#

db = require './saucedb'

# Data Transfer Object abstract base class
class DTO
    constructor: (@table, @channel) ->
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
        

# Data Transfer Object for arrays
class ArrayDTO extends DTO
    constructor: (table, channel, @valueField) ->
        super table, channel
        @data = []
        
        
    load: ->
        db.loadData @channel.id, @table, @valueField, (data) =>
            @data = data
            io.module "Updated #{@table} for #{@channel.id}:#{@channel.name}"
        
     
# Data Transfer Object for hashes
class HashDTO extends DTO
    constructor: (table, channel, @keyField, @valueField) ->
        super table, channel
        @data = {}
    