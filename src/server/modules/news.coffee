# SauceBot Module: News

Sauce = require '../sauce'
db    = require '../saucedb'

io    = require '../ioutil'
vars  = require '../vars'

{ # Import DTO classes
    ArrayDTO,
    ConfigDTO,
    HashDTO,
    EnumDTO
} = require '../dto'


# Module description
exports.name        = 'News'
exports.version     = '1.1'
exports.description = 'Automatic news broadcasting'

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
class News
    constructor: (@channel) ->
        @news   = new EnumDTO   @channel, 'news'    , 'newsid', 'message'
        @config = new ConfigDTO @channel, 'newsconf', ['state', 'seconds', 'messages']

        # News index
        @index    = 0
        
        # News counters
        @lastTime     = io.now()
        @messageCount = 0
       
        @loaded = false
       
        
    load: ->
        io.module "[News] Loading for #{@channel.id}: #{@channel.name}"

        @registerHandlers() unless @loaded
        @loaded = true

        @news.load()
        @config.load()


    unload: ->
        return unless @loaded
        @loaded = false
        
        io.module "[News] Unloading from #{@channel.id}: #{@channel.name}"
        myTriggers = @channel.listTriggers { module:this }
        @channel.unregister myTriggers...


    registerHandlers: ->
        # !news on - Enable auto-news
        @channel.register this, "news on"      , Sauce.Level.Mod,
            (user,args,bot) =>
                @cmdNewsEnable user, args, bot
        
        # !news off - Disable auto-news
        @channel.register this, "news off"     , Sauce.Level.Mod,
            (user,args,bot) =>
                @cmdNewsDisable user, args, bot
        
        # !news seconds <value> - Sets minimum seconds
        @channel.register this, "news seconds" , Sauce.Level.Mod,
            (user,args,bot) =>
                @cmdNewsSeconds user, args, bot
        
        # !news messages <value> - Sets minimum messages
        @channel.register this, "news messages", Sauce.Level.Mod,
            (user,args,bot) =>
                @cmdNewsMessages user, args, bot
        
        # !news clear - Clears the news list
        @channel.register this, "news clear"   , Sauce.Level.Mod,
            (user,args,bot) =>
                @cmdNewsClear user, args, bot
        
        # !news add <line> - Adds a news line
        @channel.register this, "news add"     , Sauce.Level.Mod,
            (user,args,bot) =>
                @cmdNewsAdd user, args, bot
        
        # !news - Print the next news message
        @channel.register this, "news"         , Sauce.Level.Mod,
            (user,args,bot) =>
                @cmdNewsNext user, args, bot


    cmdNewsEnable: (user, args, bot) ->
        @config.add 'state', 1
        bot.say '<News> Auto-news is now enabled.'


    cmdNewsDisable: (user, args, bot) ->
        @config.add 'state', 0
        bot.say '<News> Auto-news is now disabled.'


    cmdNewsSeconds: (user, args, bot) ->
        @config.add 'seconds', parseInt(args[0], 10) if args[0]?
        bot.say "<News> Auto-news minimum delay set to " +
                "#{@config.get 'seconds'} seconds."


    cmdNewsMessages: (user, args, bot) ->
        @config.add 'messages', parseInt(args[0], 10) if args[0]?
        bot.say "<News> Auto-news minimum delay set to " +
                "#{@config.get 'messages'} messages."


    cmdNewsClear: (user, args, bot) ->
        @news.clear()
        bot.say '<News> Auto-news cleared.'


    cmdNewsAdd: (user, args, bot) ->
        @news.add args.join ' '
        bot.say '<News> Auto-news added.'


    cmdNewsNext: (user, args, bot) ->
        bot.say @getNext(user) ? '<News> No auto-news found. Add with !news add <message>'
        

    save: ->
        @news.save()
        @config.save()
        
        io.module "News saved"


    getNext: (user) ->
        @lastTime = io.now()
        @messageCount = 0

        @data = @news.get()
        return null if @data.length is 0
        
        # Wrap around the news list
        @index = 0 if @index >= @data.length
        
        news = @channel.vars.parse user, @data[@index++], ''
        
        "[News] #{news}"
        
        
    tickNews: ->
        now = io.now()
        @messageCount++
        
        state    = @config.get 'state'
        seconds  = @config.get 'seconds'
        messages = @config.get 'messages'
        
        return unless ((state         is (1))                   and 
                       (now           >  (@lastTime + seconds)) and
                       (@messageCount >= (messages)))

        @getNext("SauceBot")
    
    
    # Auto-news
    handle: (user, msg, bot) ->
 
        # Check if it's time to print some news
        if ((news = @tickNews())?)
            bot.say news



exports.New = (channel) ->
    new News channel

