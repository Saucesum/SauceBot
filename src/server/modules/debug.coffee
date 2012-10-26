# SauceBot Debugging Module

io    = require '../ioutil'
Sauce = require '../sauce'
db    = require '../saucedb'

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
                return @say bot, "Usage: !dbg reload <module name>"

            @say bot, "Reloading #{moduleName}"
            @channel.reloadModule moduleName

        @regCmd 'dbg unload', global, (user, args, bot) =>
            unless (moduleName = args[0])?
                return @say bot, "Usage: !dbg unload <module name>"

            db.removeChanData @channel.id, 'module', 'module', moduleName, =>
                @say bot, "Unloading #{moduleName}"
                @channel.loadChannelModules()

        @regCmd 'dbg load', global, (user, args, bot) =>
            unless (moduleName = args[0])?
                return @say bot, "Usage: !dbg load <module name>"

            db.addChanData @channel.id, 'module', ['module', 'state'], [[moduleName, 1]], =>
               @say bot, "Module #{moduleName} loaded"
               @channel.loadChannelModules()

        @regCmd 'dbg modules', global, (user, args, bot) =>
            @say bot, ("#{m.name}#{if not m.loaded then '[?]' else ''}" for m in @channel.modules).join(' ')

        @regCmd 'dbg triggers', global, (user, args, bot) =>
            @say bot, "Triggers for #{@channel.name}:"
            @say bot, "[#{t.oplevel}]#{t.pattern}" for t in @channel.triggers

        @regCmd 'dbg vars', global, (user, args, bot) =>
            @say bot, "Variables for #{@channel.name}:"
            @say bot, "#{v.module} - #{k}" for k, v of @channel.vars.handlers

    say: (bot, msg) ->
        bot.say "[Debug] #{msg}"

exports.New = (channel) -> new Debug channel

