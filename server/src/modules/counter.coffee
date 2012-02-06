# SauceBot Module: Counter

Sauce = require '../sauce'
db    = require '../saucedb'

io    = require '../ioutil'

# Module description
exports.name        = 'Counter'
exports.version     = '1.1'
exports.description = 'Provides counters that can be set like commands.'

io.module '[Counter] Init'

# Counter module
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

        @counters[ctr] += value
        counterCheck ctr

    # Handle !<counter> unset
    counterUnset: (ctr) ->
        if @counters[ctr]?
            return "#{ctr} removed."
        
    handle: (user, command, args, sendMessage) ->
        arg = args[0] ? null

        if arg?

            op = arg.charAt(0)
            value = arg.slice(1)

            switch op.charAt(0)
              when '='
                res = @counterSet command, value
              when '+'
                res = @counterAdd command, value
              when '-'
                res = @counterAdd command, 0-value

        else
            res = @counterCheck command

        sendMessage "[Counter] #{res}" if res?

exports.New = (channel) ->
    new Counter channel
    
