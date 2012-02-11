# SauceBot Data Transfer Object


db = require '../saucedb'
io = require '../ioutil'
{DTO} = require './DTO'

# Data Transfer Object for arrays
class ArrayDTO extends DTO
    constructor: (channel, table, @valueField) ->
        super channel, table
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
         db.addChanData @channel.id, @table, [@valueField], [[item]]
        
         
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
     
             
equalsIgnoreCase = (a, b) ->
    a.toLowerCase() is b.toLowerCase()

     
     
exports.ArrayDTO = ArrayDTO