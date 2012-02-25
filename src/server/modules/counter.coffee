# SauceBot Module: Counter

Sauce = require '../sauce'
db    = require '../saucedb'
trig  = require '../trigger'

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

        @triggers = {}
        
    load: ->
        regexBadCtr = /^!(\w+\s+(?:\+|\-).+)$/
        regexNewCtr = /^!(\w+\s+=.+)$/

        @channel.register new trig.Trigger this, trig.PRI_LOW, Sauce.Level.Mod, regexBadCtr,
            (user, commandString, sendMessage) =>
                @cmdBadCounter user, commandString, sendMessage

        @channel.register new trig.Trigger this, trig.PRI_LOW, Sauce.Level.Mod, regexNewCtr,
            (user, commandString, sendMessage) =>
                @cmdNewCounter user, commandString, sendMessage

        io.module "[Counter] Loading counters for #{@channel.id}: #{@channel.name}"

        # Load custom commands
        @counters.load =>
            for ctr of @counters.data
                @addTrigger ctr
    unload:->
        myTriggers = @channel.listTriggers { module:this }
        @channel.unregister myTriggers...


    addTrigger: (ctr) ->
        return if @triggers[ctr]?

        # Create a trigger that manages a counter
        @triggers[ctr] = trig.buildTrigger  this, ctr, Sauce.Level.Mod,
            (user, args, sendMessage) =>
                @cmdCounter ctr, user, args, sendMessage

        @channel.register @triggers[ctr]

    # Handles:
    #  !<counter>
    #  !<counter> +<value>
    #  !<counter> -<value>
    #  !<counter> =<value>
    #  !<counter> unset
    cmdCounter: (ctr, user, args, sendMessage) ->
        arg = args[0] ? ''

        if arg is 'unset'
            res = @counterUnset ctr

        else if arg is ''
            res = @counterCheck ctr

        else
            symbol = arg.charAt(0)
            value  = parseInt(arg.slice(1), 10)

            unless isNaN value

                res = switch symbol
                  when '='
                    @counterSet ctr, value
                  when '+'
                    value ?= 1
                    @counterAdd ctr, value
                  when '-'
                    value ?= 1
                    @counterAdd ctr, 0-value


        sendMessage "[Counter] #{res}" if res?

    # Handles:
    #  !<not-a-counter> =<value>
    cmdNewCounter: (user, commandString, sendMessage) ->
        [ctr,arg] = commandString[0..1]

        value = parseInt(arg.slice(1), 10)

        unless isNaN value
            res = @counterSet ctr, value

        sendMessage "[Counter] #{res}" if res?

    # Handles:
    #  !<not-a-counter> +<value>
    #  !<not-a-counter> -<value>
    cmdBadCounter: (user, commandString, sendMessage) ->
        ctr = commandString[0]

        sendMessage "[Counter] Invalid counter '#{ctr}'. Create it with '!#{ctr} =0'"
        

    counterCheck: (ctr) ->
        if @counters.get(ctr)?
            return "#{ctr} = #{@counters.get ctr}"


    counterSet: (ctr, value) ->
        if value?
            io.debug "#{value}"
            if !@counters.get(ctr)?
                @counters.add ctr, value

                return "#{ctr} created and set to #{value}."

            @counters.add ctr, value
            @counterCheck ctr


    counterAdd: (ctr, value) ->
        counter = @counters.get ctr
        
        if !counter?
            return "Invalid counter '#{ctr}'. Create it with '!#{ctr} =0'"

        @counters.add ctr, counter + value
        @counterCheck ctr

    counterUnset: (ctr) ->
        if @counters.get(ctr)?
            @counters.remove(ctr)
            return "#{ctr} removed."
        
    handle: (user, command, args, sendMessage) ->



exports.New = (channel) ->
    new Counter channel
    
