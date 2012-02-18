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
        
    save: ->
        
        @news.save()
        @config.save()
        
        io.module "News saved"

    getNext: ->
        @data = @news.get()
        return if @data.length is 0
        
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
        
        @lastTime = now
        @messageCount = 0
        @getNext()
    
    handle: (user, command, args, sendMessage) ->
        {name, op} = user
        
        newsSent = null
        
        # Check if it's time to print some news
        if ((news = @tickNews())?)
            sendMessage (newsSent = news)

        return unless op? and command is 'news'
        
        # Get and splice the command argument 
        arg = args[0]
        res = null
        
        # !news - Print the next news message
        if (!arg? or arg is '')
            
            # Make sure we don't send two news messages at the same time
            if (!newsSent?)
              if ((msg = @getNext())?)
                  res = msg
              else
                  res = '<News> No auto-news found. Add with !news add <message>'
        
        else
            res = switch arg
            
                # !news on - Enable auto-news
                when 'on'
                    @config.add 'state', 1
                    '<News> Auto-news is now enabled.'
                    
                # !news off - Disable auto-news
                when 'off'
                    @config.add 'state', 0
                    '<News> Auto-news is now disabled.'
                    
                    
                # !news (seconds/messages) <value> - Sets minimum seconds/messages
                when 'seconds', 'messages'
                    @config.add arg, parseInt(args[1], 10) if args[1]?
                    "<News> Auto-news minimum delay set to #{@config.get arg} #{arg}."

                # !news add <line> - Adds a news line
                when 'add'
                    line = args.slice(1).join ' '
                    @news.add line
                    '<News> Auto-news added.'
                    
                # !news clear - Clears the news list
                when 'clear'
                    @news.clear()
                    '<News> Auto-news cleared.'
                    
            
        sendMessage res if res?


exports.New = (channel) ->
    new News channel

