# SauceBot Module: VM

Sauce    = require '../sauce'
db       = require '../saucedb'

# Include the base-Monument module
Monument = require '../Monument'

io       = require '../ioutil'

# Module description
exports.name        = 'VM'
exports.version     = '1.2'
exports.description = 'Victory Monument live tracker'
exports.strings     = Monument.strings ? {}
exports.ignore      = true

blocks = [
      'White', 'Orange', 'Magenta',
      'Light_blue', 'Yellow', 'Lime',
      'Pink', 'Gray', 'Light_gray',
      'Cyan', 'Purple', 'Blue',
      'Brown', 'Green', 'Red' ,
      'Black', 'Iron', 'Gold', 'Diamond'
]

usage = '!vm (white|light_gray|light_blue|diamond|...)'

io.module '[VM] Init'

class VM extends Monument.Monument
    constructor: (channel) ->
        super channel, exports.name, blocks, usage

exports.New = (channel) -> new VM channel
