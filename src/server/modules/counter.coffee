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

{Module} = require '../module'

# Module description
exports.name        = 'Counter'
exports.version     = '1.2'
exports.description = 'Provides counters that can be set like commands.'

exports.strings = {
    'err-unknown-counter': 'Unknown counter "@1@". Create it with: @2@'
    'err-not-changed'    : 'not changed'

    'action-unset'  : '@1@ removed.'
    'action-created': '@1@ created and set to @2@.'
}

io.module '[Counter] Init'

# Counter module
# - Handles:
#  !<counter>
#  !<counter> unset
#  !<counter> =<value>
#  !<counter> +<value>
#  !<counter> -<value>
#
class Counter extends Module
    constructor: (@channel) ->
        super @channel
        @counters = new HashDTO @channel, 'counter', 'name', 'value'

        @triggers = {}
       
 
    load: ->
        regexBadCtr = /^!(\w+\s+(?:\+|\-).+)$/
        regexNewCtr = /^!(\w+\s+=.+)$/

        @channel.register new trig.Trigger this, trig.PRI_LOW, Sauce.Level.Mod, regexBadCtr, @cmdBadCounter
        @channel.register new trig.Trigger this, trig.PRI_LOW, Sauce.Level.Mod, regexNewCtr, @cmdNewCounter

        # Load custom commands
        @counters.load =>
            for ctr of @counters.data
                @addTrigger ctr

        @regVar 'counter', @varCounter

        @regActs {
            # Counter.get()
            'get': (user, params, res) =>
                res.send @counters.get()

            # Counter.set(name, val)
            'set': (user, params, res) =>
                {name, val} = params
                unless name? and val?
                    return res.error "Missing attributes: name, val"

                if isNaN(val = parseInt val, 10)
                    return res.error "Value must be a number"

                @counterSet name, val
                res.ok()

            # Counter.remove(name)
            'remove': (user, params, res) =>
                {name} = params
                @counterUnset name
                res.ok()
        }
        

    unload:->
        @triggers = {}


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
    cmdNewCounter: (user, args, bot) =>
        [ctr,arg] = args[0..1]

        value = parseInt(arg.slice(1), 10)

        unless isNaN value
            res = @counterSet ctr, value

        bot.say "[Counter] #{res}" if res?


    # Handles:
    #  !<not-a-counter> +<value>
    #  !<not-a-counter> -<value>
    cmdBadCounter: (user, args, bot) =>
        ctr = args[0]

        bot.say "[Counter] " + @str('err-unknown-counter', ctr, '!' + ctr + ' =0')
    

    # $(counter <name>)
    varCounter: (user, args, cb) =>
        if args? and (counter = @counters.get()[args[0]])?
            cb counter
        else
            cb 'N/A'
    

    counterCheck: (ctr) ->
        if @counters.get(ctr)?
            return "#{ctr} = #{@counters.get ctr}"


    counterSet: (ctr, value) ->
        if value?
            if !@counters.get(ctr)?
                @counters.add ctr, value
                @addTrigger ctr

                return @str('action-created', ctr, value)

            @counters.add ctr, value
            @counterCheck ctr


    counterAdd: (ctr, value) ->
        counter = @counters.get ctr
        
        @counters.add ctr, counter + value
        @counterCheck(ctr) + (if (value is 0) then ' (' + @str('err-not-changed') + ')' else '')


    counterUnset: (ctr) ->
        if @counters.get(ctr)?
            @counters.remove(ctr)
            @channel.unregister @triggers[ctr]
            return @str('action-unset', ctr)
        

exports.New = (channel) ->
    new Counter channel
    
