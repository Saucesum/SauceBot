# SauceBot Module: Base

Sauce = require '../sauce'
db    = require '../saucedb'
trig  = require '../trigger'

io    = require '../ioutil'
vars  = require '../vars'

vm    = require 'vm'
util  = require 'util'


# Module description
exports.name        = 'Base'
exports.version     = '1.2'
exports.description = 'Global base commands'
exports.locked      = true

exports.strings = {
    # Help messages
    'help-basic'    : 'For urgent help, use @1@. Otherwise, tweet @RavnTM'
    'help-requested': 'SauceBot helpers have been alerted and should arrive soon.'
    'help-incoming' : 'SauceBot helper @1@ incoming'
    
    # Misc messages
    'math-invalid'  : 'Invalid expression: @1@'

    # Verification messages
    'verify-syntax' : 'No code specified. Usage: @1@'
    'verify-ok'     : '@1@: Verified.'
    'verify-err'    : '@1@: Invalid code.'

    # Moderator-only mode configuration
    'mod-enabled'   : 'All commands are now mod-only.'
    'mod-disabled'  : 'All commands are no longer mod-only.'

    # Quiet mode configuration
    'quiet-enabled' : 'Quiet mode enabled.'
    'quiet-disabled': 'Quiet mode disabled.'

    # Usage messages
    'usage-enable'  : 'Enable with @1@'
    'usage-disable' : 'Disable with @1@'
    'usage-invalid' : 'Invalid syntax. Usage: @1@'

}

io.module '[Base] Init'

# Math functions to include in the !calc command
MATH = ['tan', 'atan2', 'min', 'abs', 'random',
        'round', 'sqrt', 'log', 'floor',
        'sin', 'max', 'exp', 'cos', 'atan',
        'ceil', 'asin', 'pow', 'acos']

# Username verification methods

# Accepts a user verification.
# This updates the user's password and marks all
# unhandled requests for that user as handled.
#
# * username: The username of the person requesting
#             the verification. Case insensitive.
# * password: The encrypted password to set.
# * code    : The request code. Must be valid.
acceptUserCode = (username, password, code) ->
    db.query 'UPDATE users SET password=? WHERE username=?', [password, username]
    db.query 'UPDATE passwordrequests SET handled=1 WHERE username=? AND code=?  AND handled=0', [username, code]
    db.query 'UPDATE passwordrequests SET handled=2 WHERE username=? AND code!=? AND handled=0', [username, code]

# Attempts to verify the user's request.
# If verified successfully, acceptUserCode
# gets called with the appropriate data.
#
# * user: The user attempting to verify.
# * code: The code specified by the user.
# * isVerified: A callback to tell if the
#         verification was successful.
#         It is called with either true or false.
verify = (user, code, isVerified) ->
    db.query 'SELECT code, password FROM passwordrequests WHERE handled=0 AND username=?', [user], (err, results) ->
        for res in results
            if res.code is code
                acceptUserCode user, res.password, code
                return isVerified(true)

        isVerified(false)
    

# Base module
# - Handles:
#  !saucebot
#  !time
#  !test
#  !calc
#
class Base
    constructor: (@channel) ->
        @loaded = false
        
        # Set some constants
        mathValues =
            e : 2.718281828459045235360
            pi: 3.141592653589793238462
            C : (f) -> 5.0/9.0*(f-32)
            F : (c) -> 9.0/5.0*c+32

        # Include methods from Math
        mathValues[func] = Math[func] for func in MATH

        
        @sandbox = vm.createContext mathValues

    load:->
        return if @loaded
        @loaded = true
        
        io.module "[Base] Loading for #{@channel.id}: #{@channel.name}"

        @channel.register this, "saucebot", Sauce.Level.User,
            (user,args,bot) =>
              bot.say "[SauceBot] SauceBot v#{Sauce.Version} by @RavnTM - CoffeeScript/Node.js"

        @channel.register this, "test", Sauce.Level.Mod,
            (user,args,bot) =>
              bot.say "[Test] #{user.name} - #{Sauce.LevelStr user.op}"
              
        @channel.register this, "saucetime", Sauce.Level.User,
            (user,args,bot) =>
              now = new Date()
              bot.say "[SauceTime] #{io.tz now, '', '%H:%M:%S GMT %z', 'Europe/Oslo'}"
              
        @channel.register this, "help", Sauce.Level.Mod,
            (user,args,bot) =>
                db.addData 'helprequests', ['chanid', 'time', 'user', 'reason'], [[
                    @channel.id,
                    ~~(Date.now()/1000),
                    user.name.toLowerCase(),
                    args.join ' '
                ]]
                if args.length > 0
                    bot.say "[Help] " + @str('help-requested')
                else
                    bot.say "[Help] " + @str('help-basic', '!help <message>')

        # Command to test variable evaluation
        @channel.register this, "var", Sauce.Level.Mod,
            (user, args, bot) =>
                return unless args
                raw = args.join ' '
                @channel.vars.parse user, raw, raw, (parsed) ->
                    bot.say "[Vars] #{parsed}"

        @channel.register this, "verify", Sauce.Level.User,
            (user, args, bot) =>
                unless args[0]?
                    return bot.say "[Verify] " + @str('verify-syntax', '!verify <code>')

                verify user.name, args[0], (verified) =>
                    msgcode = if verified then 'verify-ok' else 'verify-err'
                    bot.say "[Verify] " + @str(msgcode, user.name)

        @channel.register this, "calc", Sauce.Level.Mod,
            (user, args, bot) =>
                return unless args
                txt = args.join ''
                math = txt.replace(/[^()\d*\/+-=\w]/g, '')
                try
                    bot.say math + "=" + (vm.runInContext math, @sandbox, "#{@channel.name}.vm")
                catch error
                    bot.say "[Calc] " + @str('math-invalid', math)

        @channel.register this, "mode", Sauce.Level.Admin,
            (user, args, bot) =>
                bot.say "[Mode] " + @str('usage-invalid', '!mode [modonly|quiet] [on|off]')

        @channel.register this, "mode modonly", Sauce.Level.Admin,
            (user, args, bot) =>
                switch args[0]
                    when 'on'
                        @channel.setModOnly true
                        bot.say '[Mode] ' + @str('mod-enabled') + ' ' + @str('usage-disable', '!mode modonly off')
                    when 'off'
                        @channel.setModOnly false
                        bot.say '[Mode] ' + @str('mod-disabled') + ' ' + @str('usage-enable', '!mode modonly on')
                    else
                        bot.say '[Mode] ' + @str('usage-invalid', '!mode modonly (on|off)')

        @channel.register this, "mode quiet", Sauce.Level.Admin,
            (user, args, bot) =>
                switch args[0]
                    when 'on'
                        @channel.setQuiet true
                        bot.say '[Mode] ' + @str('quiet-enabled') + ' ' + @str('usage-disable', '!mode quiet off')
                    when 'off'
                        @channel.setQuiet false
                        bot.say '[Mode] ' + @str('quiet-disabled') + ' ' + @str('usage-enable', '!mode quiet on')
                    else
                        bot.say '[Mode] ' + @str('usage-invalid', '!mode quiet (on|off)')
                 

    unload:->
        return unless @loaded
        @loaded = false
        
        io.module "[Base] Unloading from #{@channel.id}: #{@channel.name}"
        myTriggers = @channel.listTriggers { module:this }
        @channel.unregister myTriggers...
        

    handle: (user, msg, bot) ->
        

exports.New = (channel) ->
    new Base channel
    
