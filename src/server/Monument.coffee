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
        
        @loaded = false
        
        
    save: ->
        io.module "[#{@name}] Saving #{@channel.name} ..."
       
        # Set the data to the channel's obtained blocks
        @obtained.save()
        
    
    load: ->
        io.module "[#{@name}] Loading for #{@channel.id}: #{@channel.name}"

        @registerHandlers() unless @loaded
        @loaded = true
        
        # Load monument data
        @obtained.load()
        
        @channel.vars.register @command, (user, args) =>
            if not args[0] or args[0] is 'listæ'
                return @getBlockString()
            
            switch args[0]
                when 'count'     then @obtained.get().length
                when 'total'     then @blocks.length
                when 'remaining' then @blocks.length - @obtained.get().length
                else  'undefined'
            
                

    unload:->
        return unless @loaded
        @loaded = false
        
        io.module "[#{@name}}] Unloading from #{@channel.id}: #{@channel.name}"
        myTriggers = @channel.listTriggers { module:this }
        @channel.unregister myTriggers...
        
        @channel.vars.unregister @command
        
        
    registerHandlers: ->
        @channel.register this, "#{@command}",       Sauce.Level.Mod, (user,args,bot) =>
            @cmdMonument user, args, bot
        @channel.register this, "#{@command} clear", Sauce.Level.Mod, (user,args,bot) =>
            @cmdMonumentClear user, args, bot
        @channel.register this, "#{@command} remove", Sauce.Level.Mod, (user,args,bot) =>
            @cmdMonumentRemove user, args, bot
        

    getMonumentState: ->
        "Blocks: " + @getBlockString()
        

    getBlockString: ->
        obtained = (block for block in @blocks when block.toLowerCase() in @obtained.get())
        obtained.join(', ') or 'None'


    # !<name> - Print monument
    # !<name> <block> - Add the block to the obtained-list
    cmdMonument: (user, args, bot) ->
        unless args[0]?
            return bot.say @getMonumentState()
        
        block = args[0].toLowerCase()
        idx   = @blocksLC.indexOf block
        
        unless (idx >= 0)
            return bot.say "[#{@name}] Unknown block '#{block}'. Usage: #{@usage}"
        
        @obtained.add block unless block in @obtained.get()
        bot.say "[#{@name}] Added #{@blocks[idx]}."


    # !<name> clear - Clear the monument
    cmdMonumentClear: (user, args, bot) ->
        @obtained.clear()
        bot.say "[#{@name}] Cleared"


    # !<name> remove <block> - Removes the block from the obtained-list
    cmdMonumentRemove: (user, args, bot) ->
        unless args[0]?
            return bot.say "[#{@name}] No block specified. Usage: !#{@command} remove <block>"
        
        block = args[0].toLowerCase()
        idx   = @blocksLC.indexOf block
        
        unless (idx >= 0)
            return bot.say "[#{@name}] Unknown block '#{block}'. Usage: #{@usage}"
        
        @obtained.remove block
        bot.say "[#{@name}] Removed #{@blocks[idx]}."


    handle: (user, msg, bot) ->
        

exports.New = (channel, name, blocks, usage) ->
    new Monument channel, name, blocks, usage 
