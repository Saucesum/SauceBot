# SauceBot Data Transfer Object


db = require '../saucedb'
io = require '../ioutil'
{DTO} = require './DTO'
     
# Data Transfer Object for "single-row" tables, i.e. config tables.
#
# A given channel will only have one row in a config table, e.g.,
# (chanid, prop1, prop2) with row (1, "red", 42), with the two other columns
# being the properties of this config.
#
# Note: to change a property in a ConfigDTO, you must use add(property, value)
# to set it, since set is not used (add just does a replace anyway, so no
# worries). Also, config values default to zero.
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
        

    # Sets the given field to a value, returning the new value of the field.
    add: (field, value) ->
        return unless field in @fields
        
        @data[field] = value
        @save()
        value
    
    
    # Zeroes out the fiedl and also returns the value of field before it was
    # cleared
    remove: (field) ->
        return unless field in @fields
        
        value = @data[field]
        @data[field] = 0
        @save()
        value
        
    
    clear: ->
        @data[field] = 0 for field in @fields
        @save()
        
        
    set: (items) ->
        # Just to further clarify, setting an item in a config row is done via
        # add, since set is used to set the whole row
        throw new Error "Can't set ConfigDTO. You probably meant to call add."
    
    
    get: (field) ->
        if field? then @data[field] else @data
    
    
exports.ConfigDTO = ConfigDTO