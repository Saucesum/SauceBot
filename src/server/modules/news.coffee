# SauceBot Module: News

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
        
    load: ->
        @news.load()
        @config.load()

        # !news on - Enable auto-news
        @channel.register this, "news on"      , Sauce.Level.Mod, cmdNewsEnable
        # !news off - Disable auto-news
        @channel.register this, "news off"     , Sauce.Level.Mod, cmdNewsDisable
        # !news seconds <value> - Sets minimum seconds
        @channel.register this, "news seconds" , Sauce.Level.Mod, cmdNewsSeconds
        # !news messages <value> - Sets minimum messages
        @channel.register this, "news messages", Sauce.Level.Mod, cmdNewsMinutes
        # !news clear - Clears the news list
        @channel.register this, "news clear"   , Sauce.Level.Mod, cmdNewsClear
        # !news add <line> - Adds a news line
        @channel.register this, "news add"     , Sauce.Level.Mod, cmdNewsAdd
        # !news - Print the next news message
        @channel.register this, "news"         , Sauce.Level.Mod, cmdNewsNext

    unload: ->
        myTriggers = @channel.listTriggers { module:this }
        @channel.unregister myTriggers...

    cmdNewsEnable: (user, args, sendMessage) ->
        @config.add 'state', 1
        sendMessage '<News> Auto-news is now enabled.'

    cmdNewsDisable: (user, args, sendMessage) ->
        @config.add 'state', 0
        sendMessage '<News> Auto-news is now disabled.'

    cmdNewsSeconds: (user, args, sendMessage) ->
        @config.add 'seconds', parseInt(args[0], 10) if args[0]?
        sendMessage "<News> Auto-news minimum delay set to " +
                    "#{@config.get 'seconds'} seconds."

    cmdNewsMessages: (user, args, sendMessage) ->
        @config.add 'messages', parseInt(args[0], 10) if args[0]?
        sendMessage "<News> Auto-news minimum delay set to " +
                    "#{@config.get 'messages'} messages."

    cmdNewsClear: (user, args, sendMessage) ->
        @news.clear()
        sendMessage '<News> Auto-news cleared.'

    cmdNewsAdd: (user, args, sendMessage) ->
        @news.add args.join ' '
        sendMessage '<News> Auto-news added.'

    cmdNewsNext: (user, args, sendMessage) ->
        sendMessage @getNext() ? '<News> No auto-news found. Add with !news add <message>'
        

    save: ->
        @news.save()
        @config.save()
        
        io.module "News saved"


    getNext: ->
        @lastTime = io.now()
        @messageCount = 0

        @data = @news.get()
        return null if @data.length is 0
        
        # Wrap around the news list
        @index = 0 if @index >= @data.length
        
        "[News] #{@data[@index++]}"
        
        
    tickNews: ->
        now = io.now()
        @messageCount++
        
        state    = @config.get 'state'
        seconds  = @config.get 'seconds'
        messages = @config.get 'messages'
        
        return unless ((state         is (1))                   and 
                       (now           >  (@lastTime + seconds)) and
                       (@messageCount >= (messages)))

        @getNext()
    
    # Auto-news
    handle: (user, command, args, sendMessage) ->
 
        # Check if it's time to print some news
        if ((news = @tickNews())?)
            sendMessage news



exports.New = (channel) ->
    new News channel

