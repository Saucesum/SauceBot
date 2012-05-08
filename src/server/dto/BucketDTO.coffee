# SauceBot Data Transfer Object

db = require '../saucedb'
io = require '../ioutil'
{DTO} = require './DTO'
     
# Data Transfer Object for hashes with extra data
class BucketDTO extends DTO
    constructor: (channel, table, @keyField, @valueFields) ->
        super channel, table
        @fieldList = @valueFields.concat @keyField
        @data = {}
    
    
    # Loads the database data into the underlying hash
    load: (cb) ->
        db.loadBucket @channel.id, @table, @keyField, (data) =>
                @data = data
                cb?(data)
                io.module "Updated #{@table} for #{@channel.id}:#{@channel.name}"

    
    # Saves the data to the database
    save: ->
        dataList = ((dat[field] for field in @fieldList) for dat in @data)
        
        db.setChanData @channel.id, @table, @fieldList, dataList

    
    # Adds a (key, value)-pair to the database
    add: (key, value) ->
        value[@keyField] = key
        @data[key] = value
        db.addChanData @channel.id, @table, @fieldList, [(value[field] for field in @fieldList)]
        
    
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
    # Be sure to call BucketDTO.save() if you have modified it.
    get: (key) ->
        if key? then @data[key] else @data 
        
    
exports.BucketDTO = BucketDTO
