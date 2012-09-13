# SauceBot Data Transfer Object


db = require '../saucedb'
io = require '../ioutil'
{HashDTO} = require './HashDTO'
    
# HashDTO for id-based tables
class EnumDTO extends HashDTO
        getNewID: ->
            id = 0
            for key of @data
                if key == id then id++
            id
     
     
        add: (value) ->
            super @getNewID(), value
        
        
        get: ->
            (value for key, value of @data)
            
   

exports.EnumDTO = EnumDTO