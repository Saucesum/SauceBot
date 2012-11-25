# SauceBot Data Transfer Object


db = require '../saucedb'
io = require '../ioutil'
{DTO} = require './DTO'
     
# Data Transfer Object for hashes
# Hashes are effectively mappings of one column in the table to another, e.g.,
# table (chanid, x, y) with rows (1, 1, "a") and (1, 2, "b") would be
# converted to an object {1 : "a", 2 : "b"}.
class HashDTO extends DTO
    constructor: (channel, table, @keyField, @valueField) ->
        super channel, table
        @data = {}
    
    
    # Loads the database data into the underlying hash
    load: (cb) ->
        db.loadData @channel.id, @table,
                key: @keyField
                value: @valueField
            , (data) =>
                @data = data
                cb?()
                io.module "Updated #{@table} for #{@channel.id}:#{@channel.name}"

    
    # Saves the data to the database
    save: ->
        # Make the data an array, then all can be stored
        dataList = ([key, value] for key, value of @data)
        db.setChanData @channel.id, @table, [@keyField, @valueField], dataList

    
    # Adds a (key, value)-pair to the database
    add: (key, value) ->
        @data[key] = value
        # Add a row (chanid, key, value) to the dataset
        db.addChanData @channel.id, @table, [@keyField, @valueField], [[key, value]]
        
    
    # Removes a row from the database
    remove: (key) ->
        delete @data[key]
        db.removeChanData @channel.id, @table, @keyField, key
        
   
    # Clears the database data
    clear: ->
        @data = {}
        db.clearChanData @channel.id, @table
        

    # Sets the hash data
    set: (items) ->
        @data = items
        @save()
        
    
    # Returns the underlying hash, or the specified element.
    # Be sure to call HashDTO.save() if you have modified it.
    get: (key) ->
        if key? then @data[key] else @data
        
    
exports.HashDTO = HashDTO
