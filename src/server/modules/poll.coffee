# SauceBot Module: Poll

Sauce = require '../sauce'
db    = require '../saucedb'
io    = require '../ioutil'

{HashDTO} = require '../dto' 

# Module description
exports.name        = 'Poll'
exports.version     = '1.0'
exports.description = 'Channel voting system'

io.module '[Poll] Init'

class Poll
    constructor: (@channel) ->
        @pollDTO = new HashDTO @channel, 'poll', 'name', 'options'
        
        @reset()
        
        # !poll <name> [<opt1> <opt2> ...] - Starts/creates a new poll
        @channel.register this, 'poll'    , Sauce.Level.Mod,
            (user, args, sendMessage) =>
                @cmdPollStart args, sendMessage
        
        # !poll end - Ends the active poll
        @channel.register this, 'poll end', Sauce.Level.Mod,
            (user, args, sendMessage) =>
                @cmdPollEnd args, sendMessage
        
        # !vote <value> - Adds a vote to the current poll
        @channel.register this, 'vote'    , Sauce.Level.User,
            (user, args, sendMessage) =>
                @cmdPollVote user, args, sendMessage

        
    load: ->
        io.module "[Poll] Loading for #{@channel.id}: #{@channel.name}"
        @pollDTO.load =>
            @updatePollList()
        
        
    updatePollList: ->
        @polls = {}
        io.module "Polls: #{key + ' ' + val for key, val of @pollDTO.get()}"
        for pollName, pollOptions of @pollDTO.get()
            @polls[pollName] = pollOptions.split /\s+/
            
       
    reset: ->
        @activePoll = null
        @hasVoted   = []
        @votes      = []


    unload: ->
        io.module "[Poll] Unloading from #{@channel.id}: #{@channel.name}"
        myTriggers = @channel.listTriggers { module:this }
        @channel.unregister myTriggers...


    cmdPollStart: (args, sendMessage) ->
        unless args[0]?
            sendMessage '[Poll] No poll specified. Usage: !poll <name> <opt1> <opt2> ...'
            return
            
        pollName = args.shift().toLowerCase()
        
        unless args.length
            unless @polls[pollName]?
                sendMessage "[Poll] Unknown poll. Create it with !poll #{pollName} <opt1> <opt2> ..."
                return
                
            @reset()
            poll = @polls[pollName]
            @activePoll = pollName
            @votes = (0 for opt in poll)
            
            sendMessage "[Poll] '#{pollName}' started! Vote with !vote <option>. Options: #{poll.join ', '}"
            
        else
            options = args.join ' '
            @pollDTO.add pollName, options
            @updatePollList()
            sendMessage "[Poll] '#{pollName}' created! Start with !poll #{pollName}"
            
        
        
    cmdPollEnd: (args, sendMessage) ->
        unless @activePoll?
            sendMessage '[Poll] No active poll. Start with !poll <name>'
            return
            
        results = @getResults()
        sendMessage "[Poll] #{@activePoll} results: #{results}"
        @reset()
        
        
    getResults: ->
        ("#{@polls[@activePoll][key]}: #{@getScore key}" for key in ((key for val, key in @votes).sort (a, b) =>
            @votes[b] - @votes[a])).join ', '
       
    getScore: (key) ->
        score = @votes[key]
        total = 0
        total += value for value, idx in @votes
        
        percentage = Math.floor((score * 100.0 / total)*10)/10
        "#{score} (#{percentage}%)"
         
       
        
    cmdPollVote: (user, args, sendMessage) ->
        user = user.name
        return if !@activePoll? or user in @hasVoted 

        if args[0]? and (idx = @polls[@activePoll].indexOf(args[0])) isnt -1
            @hasVoted.push user
            @votes[idx]++
            sendMessage "[Poll] #{user} voted!"

    handle: (user, msg, sendMessage) ->
        
exports.New = (channel) -> new Poll channel
        
