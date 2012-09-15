# SauceBot Data Transfer Object

db = require '../saucedb'
io = require '../ioutil'
{DTO} = require './DTO'
     
# Data Transfer Object for hashes with extra data.
# A bucket/hash has one field used as a "key" value, which can then be used to find the other fields in the row.
class BucketDTO extends DTO
    constructor: (channel, table, @keyField, @valueFields) ->
        super channel, table
        @fieldList = @valueFields.concat @keyField
        @data = {}
    
    
    # Loads the database data into the underlying hash
    load: (cb) ->
        # Simple, loadBucket does just what we want
        db.loadBucket @channel.id, @table, @keyField, (data) =>
                @data = data
                cb?(data)
                io.module "Updated #{@table} for #{@channel.id}:#{@channel.name}"

    
    # Saves the data to the database
    save: ->
        # For each object value in @data, construct a list in the same order as @fieldList for the fields of the object, then create an array of these lists to store in the database
        dataList = ((dat[field] for field in @fieldList) for dat in @data)
        
        db.setChanData @channel.id, @table, @fieldList, dataList

    
    # Adds a (key, value)-pair to the database
    add: (key, value) ->
        # Needed to ensure that we can't store a value whose own key field doesn't match the provided key (otherwise bad things would happen)
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
        # Possibly consider a check like that in add to make sure that keys match up properly
        @data = items
        @save()
        
    
    # Returns the underlying hash, or the specified element.
    # Be sure to call BucketDTO.save() if you have modified it.
    get: (key) ->
        if key? then @data[key] else @data 
        
    
exports.BucketDTO = BucketDTO
