# SauceBot Module: Filters

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
exports.name        = 'Filters'
exports.version     = '1.1'
exports.description = 'Filters URLs, caps-lock, words and emotes'

# Filters
filterNames = ['url', 'caps', 'words', 'emotes']

# Database tables
tableNames = ['whitelist', 'blacklist', 'badwords', 'emotes']

# Database fields
tableFields =
    whitelist: 'url'
    blacklist: 'url'
    badwords : 'word'
    emotes   : 'emote'

io.module '[Filters] Init'

# Filter module
# - Handles:
#  !whitelist add <url>
#  !whitelist remove <url>
#  !whitelist clear
#  !blacklist add <url>
#  !blacklist remove <url>
#  !blacklist clear
#  !badwords add <word>
#  !badwords remove <word>
#  !badwords clear
#  !emotes add <emote>
#  !emotes remove <emote>
#  !emotes clear 
#  !permit <user> [minutes]
#  !filter <url/caps/words/emotes> <on/off>
#  !filter <url/caps/words/emotes>
#
class Filters
    constructor: (@channel) ->
        
        # Filter states
        @states = new ConfigDTO @channel, 'filterstate', filterNames
        
        # Filter lists
        @lists =
            whitelist: (new ArrayDTO @channel, 'whitelist', 'url')
            blacklist: (new ArrayDTO @channel, 'blacklist', 'url')
            badwords : (new ArrayDTO @channel, 'badwords' , 'word')
            emotes   : (new ArrayDTO @channel, 'emotes'   , 'emote')


    loadTable: (table) ->
        list = @lists[table]
        list.load()


    saveTable: (table) ->
        @lists[table].save()


    loadStates: ->
        @states.load()
        
        
    saveStates: ->
        @states.save()


    load:  ->
        @channel = chan if chan?
        
        # Load lists
        @loadTable table for table in tableNames
            
        # Load states
        @loadStates()
        
        
    checkFilters: (name, msglist) ->
        # TODO: Filter-logic here.


    # Handle filter-state commands, such as "!filter url on" and "!filter caps off"
    handleFilterStateCommand: (filter, state) ->
        if (state?)
            
            # Enable filter
            if (state is 'on')
                @states.add filter, 1
                return "#{filter} is now enabled."
                
            # Disable filter
            else if (state is 'off')
                @states.add filter, 0
                return "#{filter} is now disabled."
                
            else
                return "Invalid state: '#{state}'. usage: !filter #{filter} <on/off>"
            
        else
            # Filter is enabled
            if (@states.get filter)
                return "#{filter}-filter enabled."
                
            # Filter is disabled
            else
                return "#{filter}-filter disabled."
        
        
    # Handle filter commands, such as "!whitelist" and "!words"
    handleFilterCommand: (command, filter, arg, value) ->
        list = @lists[command]
        
        switch arg
        
            # Add filter value
            when 'add'
                list.add value
                res = "Added '#{value}'."
                
            # Remove filter value
            when 'remove'
                list.remove value
                res = "Removed '#{value}'."
            
            # Clear all filter values
            when 'clear'
                list.clear()
                res = "Cleared."
                
            else
                return
             
        return "[#{command}] #{res}"
            
    
    # Handle !-commands
    handleCommand: (command, args)->
        
        # !filter <filter type> <state>
        if (command is 'filter')
            [filter, state] = args
            
            if (filter in filterNames)
                res = @handleFilterStateCommand filter, state
                return "[Filter] #{res}"
            
        # !<filter list> <action> <value>
        else if (command in tableNames)
                
            field = tableFields[command]
            [action, value] = args
        
            res = @handleFilterCommand command, filter, action, value
                    
        
    handle: (user, command, args, sendMessage) ->
        {name, op} = user
        
        # Op - check for filter commands.
        if (op?)
            return unless command? and command isnt ''

            res = @handleCommand command, args
            
        
        # Not op - filter their message instead. :>
        else
            res = @checkFilters(name, [command].concat(args))
        
        sendMessage res if res?


exports.New = (channel) ->
    new Filters channel
