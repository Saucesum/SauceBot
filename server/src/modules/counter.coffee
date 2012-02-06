# SauceBot Module: Counter

Sauce = require '../sauce'
db    = require '../saucedb'

io    = require '../ioutil'

# Module description
exports.name        = 'Counter'
exports.version     = '1.2'
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
        @channel = chan if chan?

        io.module "[Counter] Loading counters for #{@channel.id}: #{@channel.name}"
        db.loadData @channel.id, 'counter',
               key  : 'name',
               value: 'value',
               (counters) =>
                  @counters = counters
                  io.module "[Counters] Counters loaded"

    counterSave: (ctr) ->
       db.addChanData @channel.id, 'counter',
              ['name', 'value'],
              [[ctr, @counters[ctr]]]

    # Handle !<counter>
    counterCheck: (ctr) ->
        if @counters[ctr]?
            return "#{ctr} = #{@counters[ctr]}"

    # Handle !<counter> =<value>
    counterSet: (ctr, value) ->
        if value?
            if !@counters[ctr]?
                @counters[ctr] = value

                @counterSave ctr
                return "#{ctr} created and set to #{value}."

            @counters[ctr] = value

            @counterSave ctr
            @counterCheck ctr

    # Handle !<counter> +<value>
    # Handle !<counter> -<value>
    counterAdd: (ctr, value) ->
        if !@counters[ctr]?
            return "Invalid counter '#{ctr}'. Create it with '!#{ctr} =0'"

        @counters[ctr] += value

        @counterSave ctr
        @counterCheck ctr

    # Handle !<counter> unset
    counterUnset: (ctr) ->
        if @counters[ctr]?
            db.removeChanData @channel.id, 'counter', '', command
            return "#{ctr} removed."
        
    handle: (user, command, args, sendMessage) ->
        arg = args[0] ? null

        if (arg[0]? and arg[0] isnt '')

            op    = arg.charAt(0)
            vals  = arg.slice(1)
            value = if (vals isnt '') then parseInt(arg.slice(1)) else null

            if value isnt NaN

                res = switch op.charAt(0)
                  when '='
                    @counterSet command, value
                  when '+'
                    value ?= 1
                    @counterAdd command, value
                  when '-'
                    value ?= 1
                    @counterAdd command, 0-value

        else
            res = @counterCheck command

        sendMessage "[Counter] #{res}" if res?

exports.New = (channel) ->
    new Counter channel
    
