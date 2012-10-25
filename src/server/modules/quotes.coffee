# SauceBot Module: Quotes

Sauce = require '../sauce'
db    = require '../saucedb'
io    = require '../ioutil'

{ConfigDTO, EnumDTO, BucketDTO} = require '../dto'

{Module} = require '../module'

# Module description
exports.name        = 'Quotes'
exports.version     = '1.0'
exports.description = 'Random quotes'
exports.locked      = false

io.module '[Quotes] Init'

class Quotes extends Module
    constructor: (@channel) ->
        super @channel
        @quoteDTO = new BucketDTO @channel, 'quotes', 'id', ['list', 'quote']
        @quotes   = {}
        
        
    load: ->
        @registerHandlers()
        
        @quoteDTO.load =>
            for id, {quote, list} of @quoteDTO.data
                @quotes[list] = [] unless @quotes[list]?
                @quotes[list].push quote
        

    registerHandlers: ->
        @regVar 'quote', (user, args, cb) =>
            unless (list = args[0])? and (@hasQuotes list)
                cb 'N/A'
            else
                cb @getRandomQuote list
                
                
    hasQuotes: (list)      -> @quotes[list]?.length
    numQuotes: (list)      -> @quotes[list]?.length
    getQuote : (list, idx) -> @quotes[list]?[idx]
                
    getRandomQuote: (list) ->
        @getQuote list, ~~ (Math.random() * @numQuotes list)
    
        
exports.New = (channel) -> new Quotes channel
