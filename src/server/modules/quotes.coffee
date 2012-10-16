# SauceBot Module: Quotes

Sauce = require '../sauce'
db    = require '../saucedb'
io    = require '../ioutil'

{ConfigDTO, EnumDTO, BucketDTO} = require '../dto' 

# Module description
exports.name        = 'Quotes'
exports.version     = '1.0'
exports.description = 'Random quotes'
exports.locked      = false

io.module '[Quotes] Init'

class Quotes
    constructor: (@channel) ->
        @quoteDTO = new BucketDTO @channel, 'quotes', 'id', ['list', 'quote']
        @quotes   = {}
        
        @loaded = false
        
        
    load: ->
        io.module "[Quotes] Loading for #{@channel.id}: #{@channel.name}"
        
        @registerHandlers() unless @loaded
        
        @quoteDTO.load =>
            for id, {quote, list} of @quoteDTO.data
                @quotes[list] = [] unless @quotes[list]?
                @quotes[list].push quote
        
    unload: ->
        return unless @loaded
        @loaded = false
        
        io.module "[Quotes] Unloading from #{@channel.id}: #{@channel.name}"
        myTriggers = @channel.listTriggers { module:this }
        @channel.unregister myTriggers...


    registerHandlers: ->
        @channel.vars.register 'quote', (user, args, cb) =>
            unless (list = args[0])? and (@hasQuotes list)
                cb 'N/A'
            else
                cb @getRandomQuote list
                
                
    hasQuotes: (list)      -> @quotes[list]?.length
    numQuotes: (list)      -> @quotes[list]?.length
    getQuote : (list, idx) -> @quotes[list]?[idx]
                
    getRandomQuote: (list) ->
        @getQuote list, ~~ (Math.random() * @numQuotes list)
    
    
    handle: (user, msg, bot) ->
        

        
exports.New = (channel) -> new Quotes channel
