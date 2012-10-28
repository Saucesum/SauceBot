# Utilities for dealing with time

# Returns the current time in seconds
exports.now = ->
    Math.floor Date.now() / 1000


# Timezone function, see node.js timezone module documentation
exports.tz = require('timezone')(
    require "timezone/#{region}" for region in ['Africa', 'America',
    'Antarctica', 'Asia', 'Atlantic', 'Australia', 'Europe', 'Indian',
    'Pacific']
)