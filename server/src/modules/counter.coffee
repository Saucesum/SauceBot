# SauceBot Module: Counter

Sauce = require '../sauce'
db    = require '../saucedb'

io    = require '../ioutil'

# Module description
exports.name        = 'Counter'
exports.version     = '1.1 build 2'
exports.description = 'Provides counters that can be set like commands.'

io.module '[Counter] Init'

# Base module
# - Handles:
#  !<counter>
#  !<counter> unset
#  !<counter> =<value>
#  !<counter> +<value>
#  !<counter> -<value>
#
class Counter
    constructor: (@channel) ->
        @counters = {}
        
    load: (chan) ->
        # TODO Load from DB ~.~
        @channel = chan if chan?
        io.module '[Counter] Loading'

    # Handle !<counter>
    counterCheck: (ctr) ->
        if @counters[ctr]?
            return "#{ctr} = #{@counters[ctr]}"

    # Handle !<counter> =<value>
    counterSet: (ctr, value) ->
        if !@counters[ctr]?
            @counters[ctr] = value
            return "#{ctr} created and set to #{value}."

        @counters[ctr] = value
        counterCheck ctr

    # Handle !<counter> +<value>
    # Handle !<counter> -<value>
    counterAdd: (ctr, value) ->
        if !@counters[ctr]?
            return "Invalid counter '#{ctr}'. Create it with '!#{ctr} =0'"

        else
            @counters[ctr] += value

        counterCheck ctr

    # Handle !<counter> unset
    counterUnset: (ctr) ->

        @counters[ctr] ?= 0
        @counters[ctr] += 1

        return "Counter '#{ctr}' = #{@counters[ctr]}"
        
    handle: (user, command, args, sendMessage) ->
        return unless (command is "counter")
        
        # !counter - Default counter
        if (!args? or args[0] is '')
            args[0] = null

        res = @count(args)

        sendMessage "[Counter] #{res}" if res?

exports.New = (channel) ->
    new Counter channel
    
