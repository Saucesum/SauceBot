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
exports.version     = '1.2'
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
        
        # Permits (filter immunity)
        @permits = {}
        
        
        # Register filter list commands
        for filterName, filterList of @lists
          do (filterName, filterList) =>
            # !<filterlist> add <value> - Adds value to filter list
            @channel.register this, "#{filterName} add"   , Sauce.Level.Mod,
                (user, args, sendMessage) =>
                    @cmdFilterAdd    filterName, filterList, args, sendMessage
                    
            # !<filterlist> remove <value> - Removes value from filter list
            @channel.register this, "#{filterName} remove", Sauce.Level.Mod,
                (user, args, sendMessage) =>
                    @cmdFilterRemove filterName, filterList, args, sendMessage

            # !<filterlist> clear - Clears the filter list
            @channel.register this, "#{filterName} clear" , Sauce.Level.Mod,
                (user, args, sendMessage) =>
                    @cmdFilterClear  filterName, filterList, args, sendMessage


        # Register filter state commands
        for filter in filterNames
          do (filter) =>
            # !filter <filtername> on - Enables filter
            @channel.register this, "filter #{filter} on" , Sauce.Level.Mod,
                (user, args, sendMessage) =>
                    @cmdFilterEnable  filter, sendMessage
                    
            # !filter <filtername> off - Disables filter
            @channel.register this, "filter #{filter} off", Sauce.Level.Mod,
                (user, args, sendMessage) =>
                    @cmdFilterDisable filter, sendMessage

            # !filter <filtername> - Shows filter state
            @channel.register this, "filter #{filter}"    , Sauce.Level.Mod,
                (user, args, sendMessage) =>
                    @cmdFilterShow    filter, sendMessage
            

        # Register misc commands
        
        # !permit <username>
        @channel.register this, 'permit'                  , Sauce.Level.Mod,
            (user, args, sendMessage) =>
                @cmdPermitUser args, sendMessage
        

    load:  ->
        @channel = chan if chan?
        
        # Load lists
        @loadTable table for table in tableNames
            
        # Load states
        @loadStates()
        

    unload: ->
        myTriggers = @channel.listTriggers { module:this }
        @channel.unregister myTriggers...


    # Filter list command handlers

    cmdFilterAdd: (name, dto, args, sendMessage) ->
        value = args[0] if args[0]?
        if value?
            dto.add value
            sendMessage "[Filter] #{name} - Added."
        else
            sendMessage "[Filter] No value specified. Usage: !#{name} add <value>"
    
    
    cmdFilterRemove: (name, dto, args, sendMessage) ->
        value = args[0] if args[0]?
        if value?
            dto.remove value
            sendMessage "[Filter] #{name} - Removed."
        else
            sendMessage "[Filter] No value specified. Usage: !#{name} remove <value>"
            
            
    cmdFilterClear: (name, dto, args, sendMessage) ->
        dto.clear()
        sendMessage "[Filter] #{name} - Cleared."


    # Filter state command handlers

    cmdFilterEnable: (filter, sendMessage) ->
        @states.add filter, 1
        sendMessage "[Filter] #{filter} filter is now enabled."

    
    cmdFilterDisable: (filter, sendMessage) ->
        @states.add filter, 0
        sendMessage "[Filter] #{filter} filter is now disabled."


    cmdFilterShow: (filter, sendMessage) ->
        if @states.get filter
            sendMessage "[Filter] #{filter} filter is enabled. Disable with !filter #{filter} off"
        else
            sendMessage "[Filter] #{filter} filter is disabled. Enable with !filter #{filter} on"
       
       
    # Misc command handlers       
       
    cmdPermitUser: (args, sendMessage) ->
        permitLength = 3 * 60 # 3 minutes
        permitTime   = io.now() + permitLength
        
        target = args[0] if args[0]?
        if target?
            @permits[target.toLowerCase()] = permitTime
            sendMessage "[Filter] #{target} permitted for #{permitLength} seconds."
        else
            sendMessage "[Filter] No target specified. Usage: !permit <username>"
        

       
    loadTable: (table) ->
        list = @lists[table]
        list.load()


    loadStates: ->
        @states.load()
        

    checkFilters: (name, msg, sendMessage) ->
        msg = msg.trim()
        
        if @states.get 'words'
            sendMessage "Bad word, #{name}!"         if @containsBadword msg
        if @states.get 'emotes'
            sendMessage "No single emotes, #{name}!" if @isSingleEmote msg
        if @states.get 'caps'
            sendMessage "Ease on the caps, #{name}!" if @isMostlyCaps msg
        if @states.get 'url'
            sendMessage "Bad URL, #{name}!"          if @containsBadURL msg
    
    containsBadword: (msg) ->
        for word in @lists['badwords'].get()
            if msg.indexOf(word) isnt -1 then return true
    
    
    isSingleEmote: (msg) ->
        for emote in @lists['emotes'].get()
            if msg is emote then return true


    isMostlyCaps: (msg) ->
        return (0.5 <= getCapsRate msg)

    
    containsBadURL: (msg) ->
        # TODO
    
    handle: (user, msg, sendMessage) ->
        {name, op} = user
        
        if op then return

        if (permitTime = @permits[name])?
            if io.now() > permitTime then delete @permits[name] else return
            
        
        @checkFilters name, msg, sendMessage
        

getCapsRate = (msg) ->
    # Yay for functional programming!
    (true for chr in msg when chr >= 'A' and chr <= 'Z').length / (msg.length * 1.0)


exports.New = (channel) ->
    new Filters channel
