# General language utilities

# A stack of callbacks used to ensure order of multiple calls.
class CallStack
    
    constructor: (@result) ->
        @stack = []
        
    add: (callback) ->
        @stack.push =>
            callback @stack.pop() ? @result
            
    start: ->
        @stack.reverse()
        @stack.pop()()


exports.CallStack = CallStack
