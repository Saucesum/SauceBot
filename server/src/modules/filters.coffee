# SauceBot Module: Filters

Sauce = require '../sauce'
db    = require '../saucedb'

io    = require '../ioutil'

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
        @state = 
            url   : 0
            caps  : 0
            words : 0
            emotes: 0
        
        # Filter lists
        @lists =
            whitelist: []
            blacklist: []
            badwords : []
            emotes   : []


    loadTable: (table) ->
        db.loadData @channel.id, table, tableFields[table], (data) =>
            @lists[table] = data
            io.module "Updated #{table} for #{@channel.id}:#{@channel.name}"


    saveTable: (table) ->
        field = tableFields[table]
        
        io.module "Saving filter data for #{table}..."
        
        db.setChanData @channel.id, table,
                        [field],
                        ([value] for value in @lists[table])


    loadStates: ->
        db.getChanDataEach @channel.id, 'filterstate', (data) =>
            {url, caps, emotes, words} = data
            @state.url    = url
            @state.caps   = caps
            @state.words  = words
            @state.emotes = emotes
        
        
    saveStates: ->
        {url, caps, emotes, words} = @state
        
        io.module 'Saving filter states...'
        
        db.setChanData @channel.id, 'filterstate',
                        ['url', 'caps', 'emotes', 'words'],
                        [[url ,  caps ,  emotes ,  words]]


    load: (chan) ->
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
                @state[filter] = 1
                @saveStates()
                return "#{filter} is now enabled."
                
            # Disable filter
            else if (state is 'off')
                @state[filter] = 0
                @saveStates()
                return "#{filter} is now disabled."
                
            else
                return "Invalid state: '#{state}'. usage: !filter #{filter} <on/off>"
            
        else
            # Filter is enabled
            if (@state[filter] is 1)
                return "#{filter}-filter enabled."
                
            # Filter is disabled
            else
                return "#{filter}-filter disabled."
        
        
    # Handle filter commands, such as "!whitelist" and "!words"
    handleFilterCommand: (command, filter, arg, value) ->
        list = @lists[command]
        
        # Add filter value
        if      (arg is 'add')
            
            list.push value
            res = "Added '#{value}'."
            
        # Remove filter value
        else if (arg is 'remove')
        
            idx = list.indexOf(value)
            if (idx is -1)
                res = "No such value '#{value}'"
            else
                list.splice(idx, 1)
                res = "Removed '#{value}'."
        
        # Clear all filter values
        else if (arg is 'clear')
    
            @lists[command] = []    
            res = "Cleared."
            
        else
            return
            
        
        @saveTable(command)
        return "[#{command}] #{res}"
            
    
    # Handle !-commands
    handleCommand: (command, args)->
        if (command is 'filter')
            filter = args[0]
            state  = args[1]
            
            if (filter in filterNames)
                res = @handleFilterStateCommand filter, state
                return "[Filter] #{res}"
            
        else if (command in tableNames)
                
            field = tableFields[command]
                 
            arg   = args[0] # arg  : add/remove/clear
            value = args[1] # value: url, word, or emote
        
            res = @handleFilterCommand command, filter, arg, value
                    
        
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
