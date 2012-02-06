# SauceBot Module: News

Sauce = require '../sauce'
db    = require '../saucedb'

io    = require '../ioutil'

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
      
        # Configurations
        @news     = []
        @state    = 0
        @seconds  = 150
        @messages = 15
        
        # News index
        @index    = 0
        
        # News counters
        @lastTime     = io.now()
        @messageCount = 0
        
    load: (chan) ->
        @channel = chan if chan?
        
        # Load news data
        db.loadData @channel.id, 'news', 'message', (data) =>
             @news = data
             io.module "Updated news for #{@channel.id}: #{@channel.name}"
        
        # Load news configurations
        db.getChanDataEach @channel.id, 'newsconf', (conf) =>
            @state    = conf.state
            @seconds  = conf.seconds
            @messages = conf.messages

    save: ->
        
        # Save news
        newsid = 0
        db.setChanData @channel.id, 'news',
                        ['chanid'    , 'newsid' , 'message'],
                        ([@channel.id,  newsid++,  message ] for message in @news)
                       
        # Save news config
        db.setChanData @channel.id, 'newsconf',
                        ['chanid'    , 'state', 'seconds', 'messages'],
                        [[@channel.id, @state , @seconds , @messages]]
                        
        io.module "News saved"

    getNext: ->
        return if @news.length is 0
        
        # Wrap around the news list
        @index = 0 if @index >= @news.length
        
        "[News] #{@news[@index++]}"
        
        
    tickNews: ->
        now = io.now()
        @messageCount++
        
        return unless ((@state        is (1))                    and 
                       (now           >  (@lastTime + @seconds)) and
                       (@messageCount >= (@messages)))
        
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
            updated = true
            res = switch arg
            
                # !news on - Enable auto-news
                when 'on'
                    @state = 1
                    '<News> Auto-news is now enabled.'
                    
                # !news off - Disable auto-news
                when 'off'
                    @state = 0
                    '<News> Auto-news is now disabled.'
                     
                # !news seconds <seconds> - Set the minimum delay
                when 'seconds'
                    @seconds = parseInt args[1], 10 if args[1]?
                    "<News> Auto-news minimum delay set to #{@seconds} seconds."
            
                # !news messages <messages> - Set the minimum messages
                when 'messages'
                    @messages = parseInt args[1], 10 if args[1]?
                    "<News> Auto-news minimum messages set to #{@messages}."
                    
                # !news add <line> - Adds a news line
                when 'add'
                    line = args.slice(1).join ' '
                    @news.push line
                    '<News> Auto-news added.'
                    
                # !news clear - Clears the news list
                when 'clear'
                    @news = []
                    '<News> Auto-news cleared.'
                    
                else
                    updated = null
                    
            
            @save() if updated?    
           
        sendMessage res if res?


exports.New = (channel) ->
    new News channel

