# SauceBot Monument Module Base

Sauce = require './sauce'
db    = require './saucedb'
io    = require './ioutil'

{Module} = require './module'

{ # Import DTO classes
    ArrayDTO,
    ConfigDTO,
    HashDTO,
    EnumDTO
} = require './dto'


# Preset strings
exports.strings = {
    'err-usage'             : 'Usage: @1@'
    'err-unknown-block'     : 'Unknown block "@1@"'
    'err-no-block-specified': 'No block specified'

    'action-added'  : 'Added @1@.'
    'action-removed': 'Removed @1@.'
    'action-cleared': 'Cleared.'

    'list-none'  : 'None'
    'list-blocks': 'Blocks: @1@'
}


class Monument extends Module
    constructor: (@channel, @name, @blocks, @usage) ->
        super @channel
        @command = @name.toLowerCase()

        @obtained = new ArrayDTO @channel, @command, 'block'
        
        @blocksLC = (block.toLowerCase() for block in @blocks)
        
        
    save: ->
        # Set the data to the channel's obtained blocks
        @obtained.save()
        
    
    load: ->
        @registerHandlers()
        
        # Load monument data
        @obtained.load()

 
    registerHandlers: ->
        @regCmd "#{@command}",        Sauce.Level.Mod, @cmdMonument
        @regCmd "#{@command} clear",  Sauce.Level.Mod, @cmdMonumentClear
        @regCmd "#{@command} remove", Sauce.Level.Mod, @cmdMonumentRemove
        @regVar "#{@command}", @varMonument

        @regActs {
            # Monument.get()
            'get': (user, params, res) =>
                res.send @obtained.get()

            # Monument.add(block)
            'add': (user, params, res) =>
                {block} = params

                unless block? and (block = block.toLowerCase()) in @blocksLC
                    return res.error "Invalid block. Blocks: #{@blocksLC.join ', '}"
                
                @addBlock block
                res.ok()

            # Monument.remove(block)
            'remove': (user, params, res) =>
                {block} = params

                unless block? and (block = block.toLowerCase()) in @blocksLC
                    return res.error "Invalid block. Blocks: #{@blocksLC.join ', '}"

                @removeBlock block
                res.ok()

            # Monument.clear()
            'clear': (user, params, res) =>
                @clearBlocks()
                res.ok()
        }


    addBlock: (block) ->
        @obtained.add block unless block in @obtained.get()


    removeBlock: (block) ->
        @obtained.remove block


    clearBlocks: ->
        @obtained.clear()

    getMonumentState: ->
        @str('list-blocks', @getBlockString())
        

    getBlockString: ->
        obtained = (block for block in @blocks when block.toLowerCase() in @obtained.get())
        obtained.join(', ') or @str('list-none')


    # !<name> - Print monument
    # !<name> <block> - Add the block to the obtained-list
    cmdMonument: (user, args) =>
        unless args[0]?
            return @bot.say @getMonumentState()
        
        block = args[0].toLowerCase()
        idx   = @blocksLC.indexOf block
        
        unless (idx >= 0)
            return @say @str('err-unknown-block', block) + '. ' + @str('err-usage', @usage)
        
        @addBlock block
        @say @str('action-added', @blocks[idx])


    # !<name> clear - Clear the monument
    cmdMonumentClear: (user, args) =>
        @clearBlocks()
        @say @str('action-cleared')


    # !<name> remove <block> - Removes the block from the obtained-list
    cmdMonumentRemove: (user, args) =>
        unless args[0]?
            return @say @str('err-no-block-specified') + '. ' + @str('err-usage', '!' + @command + ' remove <block>')
        
        block = args[0].toLowerCase()
        idx   = @blocksLC.indexOf block
        
        unless (idx >= 0)
            return @say @str('err-unknown-block', block)
        
        @removeBlock block
        @say @str('action-removed', @blocks[idx])


    # $(<name> list|count|total|remaining)
    varMonument: (user, args, cb) =>
        if not args[0] or args[0] is 'list'
            return cb @getBlockString()
        
        cb switch args[0]
            when 'count'     then @obtained.get().length
            when 'total'     then @blocks.length
            when 'remaining' then @blocks.length - @obtained.get().length
            else  'undefined'


    say: (msg) ->
        @bot.say "[#{@name}] #{msg}"


exports.Monument = Monument

