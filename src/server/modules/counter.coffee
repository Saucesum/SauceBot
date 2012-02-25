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
        io.module "[Counter] Loading for #{@channel.id}: #{@channel.name}"

        regexBadCtr = /^!(\w+\s+(?:\+|\-).+)$/
        regexNewCtr = /^!(\w+\s+=.+)$/

        @channel.register new trig.Trigger this, trig.PRI_LOW, Sauce.Level.Mod, regexBadCtr,
            (user, commandString, bot) =>
                @cmdBadCounter user, commandString, bot

        @channel.register new trig.Trigger this, trig.PRI_LOW, Sauce.Level.Mod, regexNewCtr,
            (user, commandString, bot) =>
                @cmdNewCounter user, commandString, bot

        # Load custom commands
        @counters.load =>
            for ctr of @counters.data
                @addTrigger ctr
#        io.module "[Counter] Loaded #{@counters.length()} counters"

    unload:->
        io.module "[Counter] Unloading from #{@channel.id}: #{@channel.name}"
        myTriggers = @channel.listTriggers { module:this }
        @channel.unregister myTriggers...


    addTrigger: (ctr) ->
        return if @triggers[ctr]?

        # Create a trigger that manages a counter
        @triggers[ctr] = trig.buildTrigger  this, ctr, Sauce.Level.Mod,
            (user, args, bot) =>
                @cmdCounter ctr, user, args, bot

        @channel.register @triggers[ctr]

    # Handles:
    #  !<counter>
    #  !<counter> +<value>
    #  !<counter> -<value>
    #  !<counter> =<value>
    #  !<counter> unset
    cmdCounter: (ctr, user, args, bot) ->
        arg = args[0] ? ''

        if arg is 'unset'
            res = @counterUnset ctr

        else if arg is ''
            res = @counterCheck ctr

        else
            symbol = arg.charAt(0)
            valstr = arg.slice(1)

            value  = parseInt(valstr, 10)
            value  = 0 if isNaN value

            res = switch symbol
              when '='
                @counterSet ctr, value
              when '+'
                value = 1 if valstr is ''
                @counterAdd ctr, value
              when '-'
                value = 1 if valstr is ''
                @counterAdd ctr, 0-value


        bot.say "[Counter] #{res}" if res?

    # Handles:
    #  !<not-a-counter> =<value>
    cmdNewCounter: (user, commandString, bot) ->
        [ctr,arg] = commandString[0..1]

        value = parseInt(arg.slice(1), 10)

        unless isNaN value
            res = @counterSet ctr, value

        bot.say "[Counter] #{res}" if res?

    # Handles:
    #  !<not-a-counter> +<value>
    #  !<not-a-counter> -<value>
    cmdBadCounter: (user, commandString, bot) ->
        ctr = commandString[0]

        bot.say "[Counter] Invalid counter '#{ctr}'. Create it with '!#{ctr} =0'"
        

    counterCheck: (ctr) ->
        if @counters.get(ctr)?
            return "#{ctr} = #{@counters.get ctr}"


    counterSet: (ctr, value) ->
        if value?
            if !@counters.get(ctr)?
                @counters.add ctr, value

                return "#{ctr} created and set to #{value}."

            @counters.add ctr, value
            @counterCheck ctr


    counterAdd: (ctr, value) ->
        counter = @counters.get ctr
        
        @counters.add ctr, counter + value
        @counterCheck(ctr) + (if (value is 0) then ' (not changed)' else '')

    counterUnset: (ctr) ->
        if @counters.get(ctr)?
            @counters.remove(ctr)
            return "#{ctr} removed."
        
    handle: (user, command, args, bot) ->



exports.New = (channel) ->
    new Counter channel
    
