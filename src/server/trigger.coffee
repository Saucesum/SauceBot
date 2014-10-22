# SauceBot Trigger Utilities


db = require './saucedb'
io = require './ioutil'

PRI_TOP  =   0  # Reserved for what, if anything, needs it.
PRI_HIGH = 100  # Could be used for sub commands, like '!vm clear'
PRI_MID  = 200  # For simple commands, like '!time'
PRI_LOW  = 300  # For greedy commands, like counter creation.

WORD_BONUS = -10  # Modifier based on word count to give sub commands priority
OP_BONUS   =  -2  # Modifier based on oplevel to give mod versions priority


escapeRegex = (string) ->
    string.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&")

# Returns a Trigger responding to !<name>, where name is one or more words.
# A priority will be assigned that gives preference primarily to longer
# commands, and then to higher op status requirements.
exports.buildTrigger = (module, name, oplevel, sub, callback) ->
    unless callback?
        callback = sub
        sub = false

    words = name.split /\s+/
    words = (escapeRegex(word) for word in words)
 
    regex = new RegExp "^!" + words.join("\\s+") + "(?:\\s+(.+))?$", 'i'

    priority = PRI_MID + WORD_BONUS*(words.length-1) + OP_BONUS*oplevel
    
    new Trigger module, priority, oplevel, regex, callback, sub



# A trigger is an object used to associate bot commands with RegExp patterns.
#
# The pattern must be a RegExp object.  A single capturing group should be used
#   to capture all arguments to the command.
class Trigger
    constructor: (@module, @priority, @oplevel, @pattern, @execute, @sub) ->
        # ...

    test: (msg) ->
        @pattern.test msg

    # Returns an array of arguments (individual words in the first capturing
    #  group), or null if there are none
    getArgs: (msg) ->
        match = @pattern.exec(msg) ? [""]
        capture = match[1] ? ""

        # Return no args if there are no non-space characters
        return [] unless /\S/.test capture

        capture.split /\s+/

exports.PRI_TOP   = PRI_TOP
exports.PRI_HIGH  = PRI_HIGH
exports.PRI_MID   = PRI_MID
exports.PRI_LOW   = PRI_LOW

exports.Trigger = Trigger


