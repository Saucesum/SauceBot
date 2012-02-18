# SauceBot Module: Counter

Sauce = require '../sauce'
db    = require '../saucedb'

io    = require '../ioutil'

{ # Import DTO classes
    ArrayDTO,
    ConfigDTO,
    HashDTO,
    EnumDTO
} = require '../dto'

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
        @counters = new HashDTO @channel, 'counter', 'name', 'value'
        
        
    load: ->
        io.module "[Counter] Loading counters for #{@channel.id}: #{@channel.name}"
        @counters.load()


    # Handle !<counter>
    counterCheck: (ctr) ->
        if @counters.get(ctr)?
            return "#{ctr} = #{@counters.get ctr}"


    # Handle !<counter> =<value>
    counterSet: (ctr, value) ->
        if value?
            io.debug "#{value}"
            if !@counters.get(ctr)?
                @counters.add ctr, value

                return "#{ctr} created and set to #{value}."

            @counters.add ctr, value
            @counterCheck ctr


    # Handle !<counter> +<value>
    # Handle !<counter> -<value>
    counterAdd: (ctr, value) ->
        counter = @counters.get ctr
        
        if !counter?
            return "Invalid counter '#{ctr}'. Create it with '!#{ctr} =0'"

        @counters.add ctr, counter + value
        @counterCheck ctr

    # Handle !<counter> unset
    counterUnset: (ctr) ->
        if @counters.get(ctr)?
            @counters.remove(ctr)
            return "#{ctr} removed."
        
    handle: (user, command, args, sendMessage) ->
        arg = args[0] ? null

        if (arg? and arg isnt '')

            symbol = arg.charAt(0)
            vals   = arg.slice(1)
            value  = if (vals isnt '') then parseInt(vals, 10) else null

            unless isNaN value

                res = switch symbol
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
    
