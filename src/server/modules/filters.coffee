# SauceBot Module: Filters

Sauce = require '../sauce'
db    = require '../saucedb'

io    = require '../ioutil'
log   = require '../../common/logger'

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

# Module strings
exports.strings = {
    
    # Warnings
    'warning-1': 'Strike 1'
    'warning-2': 'Strike 2'
    'warning-3': 'Strike 3'
    
    # Filter messages
    'on-url'  : 'Bad URL'
    'on-caps' : 'Watch the caps'
    'on-emote': 'No single emotes'
    'on-word' : 'Bad word'
    
    # Filter names
    'list-whitelist': 'Whitelist'
    'list-blacklist': 'Blacklist'
    'list-emotes'   : 'Emotes'
    'list-badwords' : 'Badwords'
    'list-regulars' : 'Regulars'
    
    'filter-url'     : 'URL'
    'filter-caps'    : 'Caps'
    'filter-emotes'  : 'Single-emote'
    'filter-words'   : 'Bad word'
    
    # Permits
    'permit-permitted': '@1@ permitted for @2@ seconds.'
    'permit-unknown'  : '@1@? Who\'s that? Either way, they\'re permitted for @2@ seconds.'
    
    # Regulars
    'regulars-added'  : 'User @1@ added to regulars list.'
    'regulars-removed': 'User @1@ removed from regulars list.'
    
    # General actions
    'action-added'    : 'Added.'
    'action-removed'  : 'Removed.'
    'action-cleared'  : 'Cleared.'
    
    # Error messages
    'err-error'     : 'Error.'
    'err-no-target' : 'No target specified.'
    'err-no-value'  : 'No value specified.'
    'err-usage'     : 'Usage: @1@'
    
    # Status
    'filter-enabled' : '@1@ filter is now enabled.'
    'filter-disabled': '@1@ filter is now disabled.'
    
    'filter-is-enabled' : '@1@ filter is enabled. Disable with @2@'
    'filter-is-disabled': '@1@ filter is disabled. Enable with @2@'
    
}

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

URL_RE = /(?:(?:https?:\/\/[-a-zA-Z0-9\.]*)|(?:[-a-zA-Z0-9]+\.))[-a-zA-Z-0-9]+\.(?:[a-zA-Z]{2,3})\b/

reasons = new log.Logger Sauce.Path, 'reasons.log'

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
            bot.say "[Filter] " + @str('list-' +  name) + " - " + @str('action-added')
        else
            bot.say "[Filter] " + @str('err-no-value') + ' ' + @str('err-usage', "!" + name + " add <value>")
    
    
    cmdFilterRemove: (name, dto, args, bot) ->
        value = args[0] if args[0]?
        if value?
            dto.remove value.toLowerCase()
            bot.say "[Filter] " + @str('list-' +  name) + " - " + @str('action-removed')
        else
            bot.say "[Filter] " + @str('err-no-value') + ' ' + @str('err-usage', "!" + name + " remove <value>")
            
            
    cmdFilterClear: (name, dto, args, bot) ->
        dto.clear()
        bot.say "[Filter] " + @str('list-' +  name) + " - " + @str('action-cleared')


    # Filter state command handlers

    cmdFilterEnable: (filter, bot) ->
        @states.add filter, 1
        bot.say "[Filter] " + @str('filter-enabled', @str('filter-' + filter))

    
    cmdFilterDisable: (filter, bot) ->
        @states.add filter, 0
        bot.say "[Filter] " + @str('filter-disabled', @str('filter-' + filter))


    cmdFilterShow: (filter, bot) ->
        if @states.get filter
            bot.say "[Filter] " + @str('filter-is-enabled', @str('filter-' + filter), '!filter ' + filter + ' off')
        else
            bot.say "[Filter] " + @str('filter-is-disabled', @str('filter-' + filter), '!filter ' + filter + ' on')
            
    
    # Regulars commands
    
    cmdRemoveRegular: (args, bot) ->
        unless args[0]
            return bot.say "[Filter] " + @str('err-error') + ' ' + @str('err-usage', '!regulars remove <username>')
            
        user = args[0].toLowerCase()
        @regulars.remove user
        bot.say @str('regulars-removed', user)
            
        
    cmdAddRegular: (args, bot) ->
        unless args[0]
            return bot.say @str('err-error') + ' ' + @str('err-usage', '!regulars add <username>')
            
        user = args[0].toLowerCase()
        @regulars.add user
        delete @warnings[user] 
        bot.say @str('regulars-added', user)
       
       
    # Misc command handlers       
       
    cmdPermitUser: (args, bot) ->
        permitLength = 3 * 60 # 3 minutes
        permitTime   = io.now() + permitLength
        
        target = args[0] if args[0]?
        if target?
            
            msg = "[Filter] " + @str('permit-permitted', target, permitLength)
            unless @channel.hasSeen target
                msg = "[Filter] " + @str('permit-unknown', target, permitLength)
            
            @permits[target.toLowerCase()] = permitTime
            delete @warnings[target.toLowerCase()] 
            bot.say msg
        else
            bot.say "[Filter] " + @str('err-no-target') + ' ' + @str('err-usage', '!permit <username>')
            
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
            return @handleStrikes name, @str('on-word'), bot, true, msg
            
        # Single-emote filter
        if @states.get('emotes') and @isSingleEmote lower
            return @handleStrikes name, @str('on-emote'), bot, false, msg
            
        # Caps filter
        if @states.get('caps')   and @isMostlyCaps msg
            return @handleStrikes name, @str('on-caps'), bot, false, msg
            
        # URL filter
        if                           @containsBadURL lower
            return @handleStrikes name, @str('on-url'),    bot, true, msg
            
            
        
    handleStrikes: (name, response, bot, clear, msg) ->
        strikes = @updateStrikes(name)
        
        strikemsg = @str ('warning-' + (if strikes < 0 then 0 else if strikes > 3 then 3 else strikes))
        
        response = "#{response}, #{name}! #{strikemsg}"
        
        if      strikes is 1
            # First strike: verbal warning + optional clear
            bot.clear name if clear
            
        else if strikes is 2
            # Second strike: 10 minute timeout
            bot.timeout name, 60 * 10
        
        else if strikes > 2
            # Third+ strike: 8 hour timeout
            bot.timeout name, 8 * 60 * 60
            
            
        reasons.timestamp @channel.name, name, response, msg
            
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
