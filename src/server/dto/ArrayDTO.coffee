# SauceBot Data Transfer Object


db = require '../saucedb'
io = require '../ioutil'
{DTO} = require './DTO'

# Data Transfer Object for arrays of strings.
#
# In the database, the array takes the form of a set of rows (chanid, value)
# such as (1, "red"), (1, "blue") in order to form the array ["red", "blue"]
# for channel 1.
#
# Note: case usually doesn't matter in the array.
class ArrayDTO extends DTO
    constructor: (channel, table, @valueField) ->
        super channel, table
        @data = []
        
    
    load: (cb) ->
        # Here we use load data to simply load all of the values of the column
        # where the row contains the matching channel ID
        db.loadData @channel.id, @table, @valueField, (data) =>
            @data = data
            io.module "Updated #{@table} for #{@channel.id}:#{@channel.name}"
            cb?(data)
            
    
    save: ->
        # Because loadData is asymmetric, we have to use setChanData to store
        # the data, by calling it to only store rows with the value field set
        # to the stored data
        db.setChanData @channel.id, @table, [@valueFields], [@data] 
    
     
    add: (item) ->
         # Ignore case here
         return if item in @data
         
         @data.push item
         # To store the new item, we have to add a row containing the new item
         # as the value attribute to the table, so the set of rows is [[item]]
         db.addChanData @channel.id, @table, [@valueField], [[item]]
        
         
    remove: (item) ->
        # Case variations of the same string are considered equal
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
     
             
equalsIgnoreCase = (a, b) ->
    a.toLowerCase() is b.toLowerCase()

     
     
exports.ArrayDTO = ArrayDTO