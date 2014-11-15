# SauceBot Module: News

Sauce = require '../sauce'
db    = require '../saucedb'

io    = require '../ioutil'
time  = require '../../common/time'
vars  = require '../vars'

{ # Import DTO classes
    ArrayDTO,
    ConfigDTO,
    HashDTO,
    EnumDTO
} = require '../dto'

{Module} = require '../module'

# Module description
exports.name        = 'News'
exports.version     = '1.1'
exports.description = 'Automatic news broadcasting'

exports.strings = {
    'status-enabled' : 'Auto-news is now enabled.'
    'status-disabled': 'Auto-news is now disabled.'

    'config-secs'     : 'Auto-news minimum delay set to @1@ seconds.'
    'config-messages' : 'Auto-news minimum delay set to @1@ messages.'

    'action-added'  : 'Auto-news added.'
    'action-cleared': 'Auto-news cleared.'

    'err-no-news': 'No auto-news found. Add with @1@'
}

io.module '[News] Init'

# News module
# - Handles:
#  !news
#  !news <on/off>
#  !news seconds <seconds>
#  !news messages <messages>
#  !news add <message>
#  !news clear
#
class News extends Module
    constructor: (@channel) ->
        super @channel
        @news   = new EnumDTO   @channel, 'news'    , 'newsid', 'message'
        @config = new ConfigDTO @channel, 'newsconf', ['state', 'seconds', 'messages']

        # News index
        @index    = 0
        
        # News counters
        @lastTime     = time.now()
        @messageCount = 0
       
        
    load: ->
        @registerHandlers()

        @news.load()
        @config.load()


    registerHandlers: ->
        # !news on - Enable auto-news
        @regCmd "news on", Sauce.Level.Mod, @cmdNewsEnable
        
        # !news off - Disable auto-news
        @regCmd "news off", Sauce.Level.Mod, @cmdNewsDisable
        
        # !news seconds <value> - Sets minimum seconds
        @regCmd "news seconds", Sauce.Level.Mod, @cmdNewsSeconds
        
        # !news messages <value> - Sets minimum messages
        @regCmd "news messages", Sauce.Level.Mod, @cmdNewsMessages
        
        # !news clear - Clears the news list
        @regCmd "news clear", Sauce.Level.Mod, @cmdNewsClear
        
        # !news add <line> - Adds a news line
        @regCmd "news add", Sauce.Level.Mod, @cmdNewsAdd
        
        # !news - Print the next news message
        @regCmd "news", Sauce.Level.Mod, @cmdNewsNext

        # Register web interface update handlers
        @regActs {
            # News.config([state|seconds|messages]*)
            'config': @actConfig

            # News.get()
            'get'   : (user, params, res) =>
                res.send @news.data

            # News.set(key, val)
            'set'   : (user, params, res) =>
                {key, val} = params
                if not key? then return res.error "Missing attribute: key"
                if not val? then return res.error "Missing attribute: val"

                id = parseInt key, 10
                if isNaN id then return res.error "Invalid key: #{key}"

                @news.add val, id
                res.ok()

            # News.add(val)
            'add'   : (user, params, res) =>
                {val} = params
                if not val then return res.error "Missing attribute: val"

                id = @news.add val
                res.send id: id

            # News.remove(key)
            'remove': (user, params, res) =>
                {key} = params
                if not key then return res.error "Missing attribute: key"

                id = parseInt key, 10
                if isNaN id then return res.error "Invalid key: #{key}"

                @news.remove id
                res.ok()

            # News.clear()
            'clear' : (user, params, res) =>
                @news.clear()
                res.ok()
        }


    # Action handler for "config"
    # News.config([state|delay|messages]*)
    actConfig: (user, params, res) =>
        {state, seconds, messages} = params

        # State - 1 or 0
        if state?.length
            val = if (val = parseInt state, 10) then 1 else 0
            @config.add 'state', val

        # Seconds delay
        if seconds?.length
            val = parseInt seconds, 10
            @config.add 'seconds', if isNaN val then 180 else val

        # Messages delay
        if messages?.length
            val = parseInt messages, 10
            @config.add 'messages', if isNaN val then 20 else val

        res.send @config.get()


    cmdNewsEnable: (user, args) =>
        @config.add 'state', 1
        bot.say '[News] ' + @str('status-enabled')


    cmdNewsDisable: (user, args) =>
        @config.add 'state', 0
        bot.say '[News] ' + @str('status-disabled')


    cmdNewsSeconds: (user, args) =>
        @config.add 'seconds', parseInt(args[0], 10) if args[0]?
        bot.say '[News] ' + @str('config-secs', @config.get 'seconds')


    cmdNewsMessages: (user, args) =>
        @config.add 'messages', parseInt(args[0], 10) if args[0]?
        bot.say '[News] ' + @str('config-messages', @config.get 'messages')


    cmdNewsClear: (user, args) =>
        @news.clear()
        bot.say '[News] ' + @str('action-cleared')


    cmdNewsAdd: (user, args) =>
        @news.add args.join ' '
        bot.say '[News] ' + @str('action-added')


    cmdNewsNext: (user, args) =>
        @getNext user, (news) =>
            news ?= '[News] ' + @str('err-no-news', '!news add <message>')
            bot.say news

    save: ->
        @news.save()
        @config.save()


    getNext: (user, cb) ->
        @lastTime = time.now()
        @messageCount = 0

        @data = @news.get()
        return cb() if @data.length is 0
        
        # Wrap around the news list
        @index = 0 if @index >= @data.length
        
        @channel.vars.parse user, @data[@index++], '', (news) =>
            cb "[News] #{news}"
        
        
    tickNews: (cb) ->
        now = time.now()
        @messageCount++
        
        state    = @config.get 'state'
        seconds  = @config.get 'seconds'
        messages = @config.get 'messages'
        
        return cb() unless ((state         is (1))                   and
                            (now           >  (@lastTime + seconds)) and
                            (@messageCount >= (messages)))

        @getNext "SauceBot", cb
    
    
    # Auto-news
    handle: (user, msg) ->
 
        # Print news if there is any
        @tickNews (msg) -> bot.say msg if msg?



exports.New = (channel) ->
    new News channel

