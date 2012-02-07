# SauceBot Module: VM

Sauce = require '../sauce'
db    = require '../saucedb'

Monument = require '../Monument'

io    = require '../ioutil'

# Module description
exports.name        = 'VM'
exports.version     = '1.2'
exports.description = 'Victory Monument live tracker'

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

exports.New = (channel) ->
    Monument.New channel, exports.name, blocks, usage
