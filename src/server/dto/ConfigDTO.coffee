# SauceBot Data Transfer Object


db = require '../saucedb'
io = require '../ioutil'
{DTO} = require './DTO'
     
# Data Transfer Object for "single-row" tables, i.e. config tables.
class ConfigDTO extends DTO
    constructor: (channel, table, @fields) ->
        super channel, table
        @data = {}
        @data[field] = 0 for field in @fields
            
            
    load: (cb) ->
        db.getChanDataEach @channel.id, @table, (data) =>
            @data = data
            cb?()


    save: ->
        db.setChanData @channel.id, @table,
                (field for field in @fields),
                [(@data[field] for field in @fields)]
        

    add: (field, value) ->
        return unless field in @fields
        
        @data[field] = value
        @save()
        value
    
        
    remove: (field) ->
        return unless field in @fields
        
        value = 0
        @data[field] = value
        @save()
        value
        
    
    clear: ->
        @data[field] = 0 for field in @fields
        @save()
        
        
    set: (items) ->
        throw new Error "Can't set ConfigDTO. You probably meant to call add."
    
    
    get: (field) ->
        if field? then @data[field] else @data
    
    
exports.ConfigDTO = ConfigDTO