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
exports.description = '(WIP) Filters URLs, caps-lock, words and emotes'

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

URL_RE = /(?:(?:https?:\/\/[a-zA-Z-\.]*)|(?:[a-zA-Z-]+\.))[a-zA-Z-0-9]+\.(?:[a-zA-Z]{2,3})\b/

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

    load:  ->
        io.module "[Filters] Loading for #{@channel.id}: #{@channel.name}"
        
        @registerHandlers() unless @loaded
        @loaded = true

        @channel = chan if chan?
        
        # Load lists
        @loadTable table for table in tableNames
            
        # Load states
        @loadStates()
        

    unload: ->
        return unless @loaded
        @loaded = false
        
        io.module "[Filters] Unloading from #{@channel.id}: #{@channel.name}"
        myTriggers = @channel.listTriggers { module:this }
        @channel.unregister myTriggers...


    registerHandlers: ->
        io.debug "[Filters] Registering handlers"
                
        # Register filter list commands
        for filterName, filterList of @lists
          do (filterName, filterList) =>
            # !<filterlist> add <value> - Adds value to filter list
            @channel.register this, "#{filterName} add"   , Sauce.Level.Mod,
                (user, args, bot) =>
                    @cmdFilterAdd    filterName, filterList, args, bot
                    
            # !<filterlist> remove <value> - Removes value from filter list
            @channel.register this, "#{filterName} remove", Sauce.Level.Mod,
                (user, args, bot) =>
                    @cmdFilterRemove filterName, filterList, args, bot

            # !<filterlist> clear - Clears the filter list
            @channel.register this, "#{filterName} clear" , Sauce.Level.Mod,
                (user, args, bot) =>
                    @cmdFilterClear  filterName, filterList, args, bot


        # Register filter state commands
        for filter in filterNames
          do (filter) =>
            # !filter <filtername> on - Enables filter
            @channel.register this, "filter #{filter} on" , Sauce.Level.Mod,
                (user, args, bot) =>
                    @cmdFilterEnable  filter, bot
                    
            # !filter <filtername> off - Disables filter
            @channel.register this, "filter #{filter} off", Sauce.Level.Mod,
                (user, args, bot) =>
                    @cmdFilterDisable filter, bot

            # !filter <filtername> - Shows filter state
            @channel.register this, "filter #{filter}"    , Sauce.Level.Mod,
                (user, args, bot) =>
                    @cmdFilterShow    filter, bot
            

        # Register misc commands
        
        # !permit <username>
        @channel.register this, 'permit'                  , Sauce.Level.Mod,
            (user, args, bot) =>
                @cmdPermitUser args, bot
        

    # Filter list command handlers

    cmdFilterAdd: (name, dto, args, bot) ->
        value = args[0] if args[0]?
        if value?
            dto.add value
            bot.say "[Filter] #{name} - Added."
        else
            bot.say "[Filter] No value specified. Usage: !#{name} add <value>"
    
    
    cmdFilterRemove: (name, dto, args, bot) ->
        value = args[0] if args[0]?
        if value?
            dto.remove value
            bot.say "[Filter] #{name} - Removed."
        else
            bot.say "[Filter] No value specified. Usage: !#{name} remove <value>"
            
            
    cmdFilterClear: (name, dto, args, bot) ->
        dto.clear()
        bot.say "[Filter] #{name} - Cleared."


    # Filter state command handlers

    cmdFilterEnable: (filter, bot) ->
        @states.add filter, 1
        bot.say "[Filter] #{filter} filter is now enabled."

    
    cmdFilterDisable: (filter, bot) ->
        @states.add filter, 0
        bot.say "[Filter] #{filter} filter is now disabled."


    cmdFilterShow: (filter, bot) ->
        if @states.get filter
            bot.say "[Filter] #{filter} filter is enabled. Disable with !filter #{filter} off"
        else
            bot.say "[Filter] #{filter} filter is disabled. Enable with !filter #{filter} on"
       
       
    # Misc command handlers       
       
    cmdPermitUser: (args, bot) ->
        permitLength = 3 * 60 # 3 minutes
        permitTime   = io.now() + permitLength
        
        target = args[0] if args[0]?
        if target?
            @permits[target.toLowerCase()] = permitTime
            bot.say "[Filter] #{target} permitted for #{permitLength} seconds."
        else
            bot.say "[Filter] No target specified. Usage: !permit <username>"
        

       
    loadTable: (table) ->
        list = @lists[table]
        list.load()


    loadStates: ->
        @states.load()
        

    checkFilters: (name, msg, bot) ->
        msg = msg.trim()
        lower = msg.toLowerCase()
        
        # TODO: These should ban/timeout/clear instead of just telling them off. 
        
        if @states.get 'words'
            bot.say "Bad word, #{name}!"         if @containsBadword lower
        if @states.get 'emotes'
            bot.say "No single emotes, #{name}!" if @isSingleEmote lower
        if @states.get 'caps'
            bot.say "Ease on the caps, #{name}!" if @isMostlyCaps msg
        bot.say "Bad URL, #{name}!"          if @containsBadURL lower
    
    containsBadword: (msg) ->
        for word in @lists['badwords'].get()
            if msg.indexOf(word) isnt -1 then return true
    
    
    isSingleEmote: (msg) ->
        for emote in @lists['emotes'].get()
            if msg is emote then return true


    isMostlyCaps: (msg) ->
        return (msg.length >= 5) and (0.55 <= getCapsRate msg)

    
    containsBadURL: (msg) ->
        return false unless URL_RE.test msg
        if @states.get 'url'
            for url in @lists['whitelist'].get()
                if msg.indexOf(url) isnt -1 then return false
            return true
        else
            for url in @lists['blacklist'].get()
                if msg.indexOf(url) isnt -1 then return true
            return false
        
    
    handle: (user, msg, bot) ->
        {name, op} = user
        
        if op then return

        if (permitTime = @permits[name])?
            if io.now() > permitTime then delete @permits[name] else return
            
        
        @checkFilters name, msg, bot
        

getCapsRate = (msg) ->
    # Yay for functional programming!
    (true for chr in msg when chr >= 'A' and chr <= 'Z').length / (msg.length * 1.0)


exports.New = (channel) ->
    new Filters channel
