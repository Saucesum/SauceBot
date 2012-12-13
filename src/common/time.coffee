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

# Time utility methods

timeRE = /(?:(\d+)\s*[dD][a-z]*)?\s*(?:(\d+)\s*[ht][a-z]*)?\s*(?:(\d+)\s*[m][a-z]*)?\s*(?:(\d+)\s*[s]\w*)?\s*/i

exports.strToTime = (str) ->
    return '' unless m = timeRE.exec str
    days    = parseInt(m[1] ? 0, 10)
    hours   = parseInt(m[2] ? 0, 10)
    minutes = parseInt(m[3] ? 0, 10)
    seconds = parseInt(m[4] ? 0, 10)
    ms = 1000 * (seconds + 60 * (minutes + 60 * (hours + 24 * days)))
    
    
SECOND = 1000
MINUTE = 60 * SECOND
HOUR   = 60 * MINUTE
DAY    = 24 * HOUR
    
word = (num, str) ->
    switch num
        when 0
            ''
        when 1
            num + ' ' + str
        else
            num + ' ' + str + 's'
 
 
exports.timeToShortStr = (time) ->
    if time >= DAY
        days  = ~~( time / DAY)
        hours = ~~((time % DAY) / HOUR)
        return "#{days}d#{hours}h"
    
    if time >= HOUR
        hours   = ~~( time / HOUR)
        minutes = ~~((time % HOUR) / MINUTE)
        return "#{hours}h#{minutes}m"
        
    else
        minutes = ~~( time / MINUTE)
        seconds = ~~((time % MINUTE) / SECOND)
        return "#{minutes}m#{seconds}s"
        
    
exports.timeToStr = (time) ->
    if time >= DAY
        days  = ~~( time / DAY)
        hours = ~~((time % DAY) / HOUR)
        return "#{word days, 'day'} #{word hours, 'hour'}"
    
    if time >= HOUR
        hours   = ~~( time / HOUR)
        minutes = ~~((time % HOUR) / MINUTE)
        return "#{word hours, 'hour'} #{word minutes, 'minute'}"
        
    else
        minutes = ~~( time / MINUTE)
        seconds = ~~((time % MINUTE) / SECOND)
        return "#{word minutes, 'minute'} #{word seconds, 'second'}"
        
        
exports.timeToFullStr = (time) ->
    strs = []
    if time >= DAY
        days = ~~ (time / DAY)
        time %= DAY
        strs.push(word days, 'day') unless days is 0
    
    if time >= HOUR
        hours = ~~ (time / HOUR)
        time %= HOUR
        strs.push(word hours, 'hour') unless  hours is 0
        
    if time >= MINUTE
        minutes = ~~ (time / MINUTE)
        time %= MINUTE
        strs.push(word minutes, 'minute') unless minutes is 0
        
    if time >= SECOND
        seconds = ~~ (time / SECOND)
        strs.push (word seconds, 'second') unless seconds is 0
        
    return (strs.join ' ').trim()

 
