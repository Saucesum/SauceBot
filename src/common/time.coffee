# Utilities for dealing with time

# Returns the current time in seconds
exports.now = ->
    Math.floor Date.now() / 1000


# Timezone locations
zones = (require "timezone/#{region}" for region in [
    'Africa', 'America', 'Antarctica', 'Asia', 'Atlantic',
    'Australia', 'Europe', 'Indian', 'Pacific'
])

# Aliases to allow for more commonly used timezone names.
ZONE_ALIASES = {
    # A few names used in the old system.
    'US/Eastern' : 'America/Thunder_Bay'
    'US/Central' : 'America/Rainy_River'
    'US/Mountain': 'America/Yellowknife'
    'US/Pacific' : 'America/Whitehorse'

    # Even though these are wrong half the time, they'll do...
    'EST': 'US/Eastern'
    'CST': 'US/Central'
    'MST': 'US/Mountain'
    'PST': 'US/Pacific'

    'CET': 'Europe/Paris'

}

# Timezone function, see node.js timezone module documentation
exports.tz = tz = require('timezone') zones


# Returns a formatted version of the current time and date in a specific timezone.
#
# * zone: The timezone to use.
# * fmt : The format to use. Default is hour, minute and second.
# = returns the formatted string.
exports.formatZone = (zone, fmt) ->
    fmt ?= '%H:%M:%S'
    zone = z while (z = ZONE_ALIASES[zone])?
    tz Date.now(), fmt, '', zone
 
