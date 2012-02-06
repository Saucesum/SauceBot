# SauceBot Module: VM

Sauce = require '../sauce'
db    = require '../saucedb'

io    = require '../ioutil'

# Module description
exports.name        = 'VM'
exports.version     = '1.1'
exports.description = 'Victory Monument live tracker'

blocks = [
      'White', 'Orange', 'Magenta',
      'Light_blue', 'Yellow', 'Lime',
      'Pink', 'Gray', 'Light_gray',
      'Cyan', 'Purple', 'Blue',
      'Brown', 'Green', 'Red' ,
      'Black', 'Iron', 'Gold', 'Diamond'   
]

blocksLC = (block.toLowerCase() for block in blocks)

io.module '[VM] Init'

# VM module
# - Handles:
#  !vm add <block>
#  !vm clear
#  !vm
#
class VM
    constructor: (@channel) ->
        @obtained = {}
        
    save: ->
        io.module "[VM] Saving #{@channel.name} ..."
       
        # Set the data to the channel's obtained blocks
        db.setChanData @channel.id, 'vm',
                      ['chanid'    , 'block'], 
                      ([@channel.id,  block ] for block in blocksLC when @obtained[block]?)
    
    load: (chan) ->
        @channel = chan if chan?

        io.module "[VM] Loading #{@channel.id}: #{@channel.name}"
        
        # Load victory monument data
        db.loadData @channel.id, 'vm', 'block', (blocks) =>
            for block in blocks
                @obtained[block] = true
    
    clearVM: ->
        @obtained = {}
        @save()
        'Cleared'
    
    
    getVM: ->
        obtained = (block for block in blocks when @obtained[block.toLowerCase()]?)
        "Blocks: #{obtained.join ', '}"
    

    setVM: (args) ->
        return unless args?
        
        block = args[0].toLowerCase()
        if ((idx = blocksLC.indexOf(block)) is -1)
            return "Unknown block '#{block}'. Usage: !vm (white|light_gray|light_blue|diamond|...)"
        
        @obtained[block] = true
        @save()
        "Added #{blocks[idx]}."
    
    handle: (user, command, args, sendMessage) ->
        {name, op} = user
        
        return unless (op? and command is 'vm')
        
        # !vm - Print victory monument
        if (!args? or args[0] is '')
            res = @getVM()
            
        # !vm clear - Clear the victory monument
        else if (args[0] is 'clear')
            res = @clearVM()
            
        # !vm <block> - Add the block to the obtained-list
        else
            res = @setVM(args)
        
        sendMessage "[VM] #{res}" if res?

exports.New = (channel) ->
    new VM channel

