# SauceBot Debugging Module

io    = require '../ioutil'
Sauce = require '../sauce'

{Module} = require '../module'

# Module metadata
exports.name        = 'Debug'
exports.version     = '1.0'
exports.description = 'Debugging utilities'
exports.ignore      = 1
exports.locked      = 1

io.module '[Debug] Init'

class Debug extends Module
    load: ->
        global = Sauce.Level.Owner + 1

        @regCmd 'dbg reload', global, (user, args, bot) =>
            unless (moduleName = args[0])?
                return @say bot "Usage: !dbg reload <module name>"

            @say bot, "Reloading #{moduleName}"
            @channel.reloadModule moduleName

        @regCmd 'dbg unload', global, (user, args, bot) =>
            unless (moduleName = args[0])?
                return @say bot "Usage: !dbg unload <module name>"

            for m in @channel.modules when m?.name is moduleName
                @say bot, "Unloading #{m.name}"
                @channel.unloadModule m

        @regCmd 'dbg load', global, (user, args, bot) =>
            unless (moduleName = args[0])?
                return @say bot, "Usage: !dbg load <module name>"

            if (m = @channel.loadModule moduleName)?
               @say bot, "Module #{m.name} loaded"
            else
                @say bot, "No such module: #{args[0]}"

        @regCmd 'dbg modules', global, (user, args, bot) =>
            @say bot, ("#{m.name}#{if not m.loaded then '[?]' else ''}" for m in @channel.modules).join(', ')

    say: (bot, msg) ->
        bot.say "[Debug] #{msg}"

exports.New = (channel) -> new Debug channel

