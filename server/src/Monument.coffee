# SauceBot Monument Module Base

Sauce = require './sauce'
db    = require './saucedb'

io    = require './ioutil'


class Monument
    constructor: (@channel, @name, @blocks, @usage) ->
        @obtained = {}
        
        @command = @name.toLowerCase()
        
        @blocksLC = (block.toLowerCase() for block in @blocks)
        
    save: ->
        io.module "[#{@name}] Saving #{@channel.name} ..."
       
        # Set the data to the channel's obtained blocks
        db.setChanData @channel.id, @command,
                      ['block'], 
                      ([block ] for block in @blocksLC when @obtained[block]?)
    
    load: (chan) ->
        @channel = chan if chan?

        io.module "[#{@name}] Loading #{@channel.id}: #{@channel.name}"
        
        # Load monument data
        db.loadData @channel.id, @command, 'block', (blocks) =>
            for block in blocks
                @obtained[block] = true
    
    clearMonument: ->
        @obtained = {}
        @save()
        'Cleared'
    
    
    getMonument: ->
        obtained = (block for block in @blocks when @obtained[block.toLowerCase()]?)
        "Blocks: #{obtained.join(', ') or 'None'}"
    

    setMonument: (args) ->
        return unless args?
        
        block = args[0].toLowerCase()
        idx   = @blocksLC.indexOf block
        
        unless (idx >= 0)
            return "Unknown block '#{block}'. Usage: #{@usage}"
        
        @obtained[block] = true
        @save()
        "Added #{@blocks[idx]}."
    
    handle: (user, command, args, sendMessage) ->
        {name, op} = user
        
        return unless (op? and command is @command)
        
        # !<name> - Print monument
        unless (args? and args[0])
            res = @getMonument()
            
        # !<name> clear - Clear the monument
        else if (args[0] is 'clear')
            res = @clearMonument()
            
        # !<name> <block> - Add the block to the obtained-list
        else
            res = @setMonument args
        
        sendMessage "[#{@name}] #{res}" if res?

exports.New = (channel, name, blocks, usage) ->
    new Monument channel, name, blocks, usage 
