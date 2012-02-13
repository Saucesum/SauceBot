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

        @channel.register this, "#{@command}",       Sauce.Level.Mod, @cmdMonument
        @channel.register this, "#{@command} clear", Sauce.Level.Mod, @cmdMonumentClear
        
        # Load monument data
        @obtained.load()
        

    getMonumentState: ->
        obtained = (block for block in @blocks when block.toLowerCase() in @obtained.get())
        "Blocks: #{obtained.join(', ') or 'None'}"


    # !<name> - Print monument
    # !<name> <block> - Add the block to the obtained-list
    cmdMonument: (user, args, sendMessage) ->
        unless args?
            return sendMessage @getMonumentState
        
        block = args[0].toLowerCase()
        idx   = @blocksLC.indexOf block
        
        unless (idx >= 0)
            return sendMessage "[#{@name}] Unknown block '#{block}'. Usage: #{@usage}"
        
        @obtained.add block
        sendMessage "[#{@name}] Added #{@blocks[idx]}."


    # !<name> clear - Clear the monument
    cmdMonumentClear: (user, args, sendMessage) ->
        @obtained.clear()
        sendMessage "[#{@name}] Cleared"


    handle: (user, command, args, sendMessage) ->
        

exports.New = (channel, name, blocks, usage) ->
    new Monument channel, name, blocks, usage 
