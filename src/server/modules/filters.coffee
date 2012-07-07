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
exports.version     = '1.3'
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
    
# Strikes reset time (in ms)
TIMEOUT = 3 * 60 * 60 * 1000

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
#  !regulars add <name>
#  !regulars remove <name>
#
#
class Filters
    constructor: (@channel) ->
        
        # Filter states
        @states   = new ConfigDTO @channel, 'filterstate', filterNames
        @regulars = new ArrayDTO  @channel, 'regulars' , 'username'
        
        # Filter lists
        @lists =
            whitelist: (new ArrayDTO @channel, 'whitelist', 'url')
            blacklist: (new ArrayDTO @channel, 'blacklist', 'url')
            badwords : (new ArrayDTO @channel, 'badwords' , 'word')
            emotes   : (new ArrayDTO @channel, 'emotes'   , 'emote')
        
        # Permits (filter immunity)
        #  username: expiration time
        @permits = {}
        
        # Warnings
        #   username:
        #     strikes: number of strikes
        #     time   : time of last warning 
        @warnings = {}
        

    load:  ->
        io.module "[Filters] Loading for #{@channel.id}: #{@channel.name}"
        
        @registerHandlers() unless @loaded
        @loaded = true

        @channel = chan if chan?
        
        
        # Load lists
        @loadTable table for table in tableNames
            
        # Load states
        @loadStates()
        @regulars.load()
        

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
                    
        @channel.register this, "regulars add", Sauce.Level.Mod,
            (user, args, bot) =>
                @cmdAddRegular args, bot
                    
        @channel.register this, "regulars remove", Sauce.Level.Mod,
            (user, args, bot) =>
                @cmdRemoveRegular args, bot


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
            dto.add value.toLowerCase()
            bot.say "[Filter] #{name} - Added."
        else
            bot.say "[Filter] No value specified. Usage: !#{name} add <value>"
    
    
    cmdFilterRemove: (name, dto, args, bot) ->
        value = args[0] if args[0]?
        if value?
            dto.remove value.toLowerCase()
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
            
    
    # Regulars commands
    
    cmdRemoveRegular: (args, bot) ->
        unless args[0]
            return bot.say "Error. Usage: !regulars remove <username>"
            
        user = args[0].toLowerCase()
        @regulars.remove user
        bot.say "User #{user} removed from regulars list."
            
        
    cmdAddRegular: (args, bot) ->
        unless args[0]
            return bot.say "Error. Usage: !regulars add <username>"
            
        user = args[0].toLowerCase()
        @regulars.add user
        delete @warnings[user] 
        bot.say "User #{user} added to regulars list."
       
       
    # Misc command handlers       
       
    cmdPermitUser: (args, bot) ->
        permitLength = 3 * 60 # 3 minutes
        permitTime   = io.now() + permitLength
        
        target = args[0] if args[0]?
        if target?
            @permits[target.toLowerCase()] = permitTime
            delete @warnings[target.toLowerCase()] 
            bot.say "[Filter] #{target} permitted for #{permitLength} seconds."
        else
            bot.say "[Filter] No target specified. Usage: !permit <username>"
            
        setTimeout ->
            bot.unban target
        , 2000
        

       
    loadTable: (table) ->
        list = @lists[table]
        list.load ->
            lcdata = (data.toLowerCase() for data in list.get())
            list.data = lcdata


    loadStates: ->
        @states.load()
        

    checkFilters: (name, msg, bot) ->
        msg = msg.trim()
        lower = msg.toLowerCase()
        
        # Badword filter
        if @states.get('words')  and @containsBadword lower
            return @handleStrikes name, 'Bad word',         bot, true
            
        # Single-emote filter
        if @states.get('emotes') and @isSingleEmote lower
            return @handleStrikes name, 'No single emotes', bot, false
            
        # Caps filter
        if @states.get('caps')   and @isMostlyCaps msg
            return @handleStrikes name, 'Watch the caps',   bot, false
            
        # URL filter
        if                           @containsBadURL lower
            return @handleStrikes name, 'Bad URL',          bot, true 
            
            
        
    handleStrikes: (name, response, bot, clear) ->
        strikes = @updateStrikes(name)
        
        response = "#{response}, #{name}! Strike #{strikes}"
        
        if      strikes is 1
            # First strike: verbal warning + optional clear
            bot.clear name if clear
            
        else if strikes is 2
            # Second strike: 10 minute timeout
            bot.timeout name, 60 * 10
        
        else if strikes > 2
            # Third+ strike: 8 hour timeout
            bot.timeout name, 8 * 60 * 60
            
            
        return if @channel.isQuiet()
            
        # Delay the response to avoid the JTV flood filter
        setTimeout ->
            bot.say response
        , 2000
    
    
    containsBadword: (msg) ->
        for word in @lists['badwords'].get()
            if msg.indexOf(word) isnt -1 then return true
    
    
    isSingleEmote: (msg) ->
        for emote in @lists['emotes'].get()
            if msg is emote then return true


    isMostlyCaps: (msg) ->
        return (msg.length > 5) and (0.55 <= getCapsRate msg)

    
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
        
        if op or @isRegular(name) then return
        lc = name.toLowerCase()

        if (permitTime = @permits[lc])?
            if io.now() > permitTime then delete @permits[lc] else return
            
        
        @checkFilters name, msg, bot
        

    isRegular: (name) ->
        return name.toLowerCase() in @regulars.get()
        
        
    updateStrikes: (name) ->
        name = name.toLowerCase()
        now  = Date.now()
        
        if not @warnings[name]? or @isOutOfDate @warnings[name].time, now
            @warnings[name] =
                strikes: 0
                time   : 0

        @warnings[name].time = now
        ++@warnings[name].strikes
        
        
    isOutOfDate: (time, now) ->
        return now - time > TIMEOUT
        
        
        
getCapsRate = (msg) ->
    # Yay for functional programming!
    (true for chr in msg when chr >= 'A' and chr <= 'Z').length / (msg.length * 1.0)


exports.New = (channel) ->
    new Filters channel
