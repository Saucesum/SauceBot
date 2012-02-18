# SauceBot Monument Module Base

Sauce = require './sauce'
db    = require './saucedb'

io    = require './ioutil'

{ # Import DTO classes
    ArrayDTO,
    ConfigDTO,
    HashDTO,
    EnumDTO
} = require './dto'



class Monument
    constructor: (@channel, @name, @blocks, @usage) ->
        @command = @name.toLowerCase()

        @obtained = new ArrayDTO @channel, @command, 'block'
        
        @blocksLC = (block.toLowerCase() for block in @blocks)
        
    save: ->
        io.module "[#{@name}] Saving #{@channel.name} ..."
       
        # Set the data to the channel's obtained blocks
        @obtained.save()
        
    
    load: ->
        io.module "[#{@name}] Loading #{@channel.id}: #{@channel.name}"
        
        # Load monument data
        @obtained.load()
        
    
    clearMonument: ->
        @obtained.clear()
        'Cleared'
    
    
    getMonument: ->
        obtained = (block for block in @blocks when block.toLowerCase() in @obtained.get())
        "Blocks: #{obtained.join(', ') or 'None'}"
    

    setMonument: (args) ->
        return unless args?
        
        block = args[0].toLowerCase()
        idx   = @blocksLC.indexOf block
        
        unless (idx >= 0)
            return "Unknown block '#{block}'. Usage: #{@usage}"
        
        @obtained.add block
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
