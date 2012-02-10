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
        

# Data Transfer Object for arrays
class ArrayDTO extends DTO
    constructor: (channel, table, @valueField) ->
        super table, channel
        @data = []
        
        
    load: ->
        db.loadData @channel.id, @table, @valueField, (data) =>
            @data = data
            io.module "Updated #{@table} for #{@channel.id}:#{@channel.name}"
        
    
    save: ->
        db.setChanData @channel.id, @table, [@valueFields], [@data] 
    
     
    add: (item) ->
         
         # XXX: This will "fail" when the item is in @data, only with
         #      a different case. I'll fix it later. Maybe.
         return if item in @data
         
         @data.push item
         db.addChanData @channel.id, [@valueField], [[item]]
        
         
    remove: (item) ->
        @data = (elem for elem in @data when not equalsIgnoreCase item, elem)
        db.removeChanData @channel.id, @table, @valueField, item
        
    
    clear: ->
        @data = []
        db.clearChanData @channel.id, @table
        
    
    set: (items) ->
        @data = items
        @save()
        
        
    get: ->
        @data
     
     
     
# Data Transfer Object for hashes
class HashDTO extends DTO
    constructor: (channel, table, @keyField, @valueField) ->
        super table, channel
        @data = {}
    
    
    load: ->
        db.loadData @channel.id, @table, 
                key: @keyField
                value: @valueField
            , (data) =>
                @data = data
                io.module "Updated #{@table} for #{@channel.id}:#{@channel.name}"

    
    save: ->
        db.setChanData @channel.id, @table, [@keyField, @valueField], [@data]

    
    add: (key, value) ->
        @data[key] = value
        db.addChanData @channel.id, [@keyField, @valueField], [[key, value]]
        
        
    remove: (key) ->
        delete @data[key] 
        db.removeChanData @channel.id, @table, @keyField, key
        
   
    clear: ->
        @data = {}
        db.clearChanData @channel.id, @table
        

    set: (items) ->
        @data = items
        @save()
        
        
    get: ->
        @data
        
    
    
equalsIgnoreCase: (a, b) ->
    a.toLowerCase() is b.toLowerCase()
