# SauceBot Module: JM

Sauce    = require '../sauce'
db       = require '../saucedb'

# Include the base-Monument module
Monument = require '../Monument'

io       = require '../ioutil'

# Module description
exports.name        = 'JM'
exports.version     = '1.0'
exports.description = 'Jukebox Monument live tracker'
exports.strings     = Monument.strings ? {}
exports.ignore      = true

blocks = [
        # Records:
        '13', 'Cat', 'Blocks',
        'Chirp', 'Far', 'Mall',
        'Mellohi', 'Stal', 'Strad',
        'Ward', '11',
        
        # Bonus blocks:
        'Lapis', 'Iron', 'Gold',
        'Diamond', 'Redstone', 'Coal'
]

usage = '!jm (13|mellohi|lapis|diamond|coal|...)'

io.module '[JM] Init'

class JM extends Monument.Monument
    constructor: (channel) ->
        super channel, exports.name, blocks, usage

exports.New = (channel) -> new JM channel
