# General language utilities

# Array method to fetch a random value
Array.prototype.randomIdx = ->
    ~~(Math.random() * @length)

# Array method to fetch a random value
Array.prototype.random = ->
    @[@randomIdx()]

# A stack of callbacks used to ensure order of multiple calls.
exports.CallStack = class CallStack
    
    constructor: (@result) ->
        @stack = []
        
    add: (callback) ->
        @stack.push =>
            callback @stack.shift() ? @result
            
    start: (result)->
        @result = result if result?

        @stack.shift()()


# Returns a string representing the last stack location.
exports.getPrevStack = ->
    line = new Error().stack.split("\n")[3].trim()
    line.substring(line.indexOf('bin/') + 4).replace(')', '')


exports.getFullStack = (n) ->
    stack = new Error().stack.split("\n")
    return if n? then stack[..n-1] else stack
