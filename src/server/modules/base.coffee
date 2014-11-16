# SauceBot Module: Base

Sauce = require '../sauce'
db    = require '../saucedb'
trig  = require '../trigger'

io    = require '../ioutil'
tz    = require '../../common/time'
vars  = require '../vars'

vm    = require 'vm'
util  = require 'util'

{Module} = require '../module'

# Module description
exports.name        = 'Base'
exports.version     = '1.2'
exports.description = 'Global base commands'
exports.locked      = true

exports.strings = {
    # Help messages
    'help-basic'    : 'For urgent help, use @1@. Otherwise, tweet @RavnTM'
    'help-requested': 'SauceBot helpers have been alerted and should arrive soon.'
    
    # Misc messages
    'math-invalid'  : 'Invalid expression: @1@'

    # Verification messages
    'verify-syntax' : 'No code specified. Usage: @1@'
    'verify-ok'     : '@1@: Verified.'
    'verify-err'    : '@1@: Invalid code. Make sure your www.saucebot.com name matches your TwitchTV name.'

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
    db.query 'UPDATE users SET password=?, verified=1 WHERE username=?', [password, username]
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
class Base extends Module
    constructor: (@channel) ->
        super @channel
 
        # Set some constants
        mathValues =
            e : 2.718281828459045235360
            pi: 3.141592653589793238462
            C : (f) -> 5.0/9.0*(f-32)
            F : (c) -> 9.0/5.0*c+32

        # Include methods from Math
        mathValues[func] = Math[func] for func in MATH
        
        @sandbox = vm.createContext mathValues


    load: ->
        botName = (@channel.botName ? 'SauceBot').toLowerCase()

        if botName isnt 'saucebot'
            @regCmd botName,           Sauce.Level.User, @cmdBot
            @regCmd botName + ' join', Sauce.Level.User, @cmdBotJoin

        @regCmd "saucebot",      Sauce.Level.User,  @cmdBot
        @regCmd "saucebot join", Sauce.Level.User,  @cmdBotJoin
        @regCmd "saucetime",     Sauce.Level.User,  @cmdSaucetime
        @regCmd "verify",        Sauce.Level.User,  @cmdVerify
        @regCmd "test",          Sauce.Level.Mod,   @cmdTest
        @regCmd "help",          Sauce.Level.Mod,   @cmdHelp
        @regCmd "var",           Sauce.Level.Mod,   @cmdEval
        @regCmd "eval",          Sauce.Level.Mod,   @cmdEval
        @regCmd "calc",          Sauce.Level.Mod,   @cmdCalc
        @regCmd "mode",          Sauce.Level.Admin, @cmdMode
        @regCmd "mode modonly",  Sauce.Level.Admin, @cmdModeModonly
        @regCmd "mode quiet",    Sauce.Level.Admin, @cmdModeQuiet

        @regActs {
            'strings': (user, params, res) =>
                res.send @channel.strings.get()

            'string': (user, params, res) =>
                unless user.isMod @channel.id, Sauce.Level.Admin
                    return res.error "You are not authorized to alter channel strings (admins only)"

                {key, val} = params
                unless key? and val?
                    return res.error "Missing parameters: key, val"
                key = key.toLowerCase().trim()
                val = val.trim()
                @channel.strings.add key, val
                res.send @channel.strings.get()
        }


    # !<botname> - Prints bot name and version.
    cmdBot: (user, args) =>
        botName = (@channel.botName ? 'SauceBot')
        @bot.say "[#{botName}] #{Sauce.Server.Name} v#{Sauce.Version} by @RavnTM - www.saucebot.com"


    # !<botname> join - Prints info on how to get the bot
    cmdBotJoin: (user, args) =>
        botName = (@channel.botName ? 'SauceBot')
        @bot.say "[#{botName}] #{user.name}: Visit www.saucebot.com to apply for #{botName}! Good luck! :-)"


    # !test - Prints test command and user level.
    cmdTest: (user, args) =>
        @bot.say "[Test] #{user.name} - #{Sauce.LevelStr user.op}"


    # !saucetime - Prints the time in SauceBot's timezone.
    cmdSaucetime: (user, args) =>
        @bot.say "[SauceTime] #{tz.formatZone 'Europe/Oslo', '%H:%M:%S UTC %z'}"


    # !help <message> - Requests help from a SauceBot admin.
    cmdHelp: (user, args) =>
        if args.length is 0
            @bot.say "[Help] " + @str('help-basic', '!help <message>')
            return

        db.addData 'helprequests', ['chanid', 'time', 'user', 'reason'], [[
            @channel.id,
            ~~(Date.now()/1000),
            user.name.toLowerCase(),
            args.join ' '
        ]]
        @bot.say "[Help] " + @str('help-requested')


    # !eval <expr> - Prints the result of evaluating <expr> as a var string.
    cmdEval: (user, args) =>
        return unless args
        raw = args.join ' '
        @channel.vars.parse user, raw, raw, (parsed) =>
            @bot.say "[Eval] #{parsed}"


    # !verify <code> - Attempts to verify the user.
    cmdVerify: (user, args) =>
        unless args[0]?
            return @bot.say "[Verify] " + @str('verify-syntax', '!verify <code>')

        verify user.name, args[0], (verified) =>
            msgcode = if verified then 'verify-ok' else 'verify-err'
            @bot.say "[Verify] " + @str(msgcode, user.name)


    # !calc <expr> - Prints the result of evaluating <expr> as a mathematical expression.
    cmdCalc: (user, args) =>
        return unless args
        txt = args.join ''
        math = txt.replace(/[^()\d*\/+-=\w]/g, '')
        try
            @bot.say math + "=" + (vm.runInContext math, @sandbox, "#{@channel.name}.vm").toFixed(2)
        catch error
            @bot.say "[Calc] " + @str('math-invalid', math)


    # !mode - Prints a help string for the mode commands.
    cmdMode: (user, args) =>
        @bot.say "[Mode] " + @str('usage-invalid', '!mode [modonly|quiet] [on|off]')


    # !mode modonly on/off - Enables/disables mod only mode.
    cmdModeModonly: (user, args) =>
        switch args[0]
            when 'on'
                @channel.setModOnly true
                @bot.say '[Mode] ' + @str('mod-enabled') + ' ' + @str('usage-disable', '!mode modonly off')
            when 'off'
                @channel.setModOnly false
                @bot.say '[Mode] ' + @str('mod-disabled') + ' ' + @str('usage-enable', '!mode modonly on')
            else
                @bot.say '[Mode] ' + @str('usage-invalid', '!mode modonly (on|off)')


    # !mode quiet on/off - Enables/disables quiet mode.
    cmdModeQuiet: (user, args) =>
        switch args[0]
            when 'on'
                @channel.setQuiet true
                @bot.say '[Mode] ' + @str('quiet-enabled') + ' ' + @str('usage-disable', '!mode quiet off')
            when 'off'
                @channel.setQuiet false
                @bot.say '[Mode] ' + @str('quiet-disabled') + ' ' + @str('usage-enable', '!mode quiet on')
            else
                @bot.say '[Mode] ' + @str('usage-invalid', '!mode quiet (on|off)')
                 

exports.New = (channel) ->
    new Base channel
    
