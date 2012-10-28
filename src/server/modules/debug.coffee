# SauceBot Debugging Module

io    = require '../ioutil'
Sauce = require '../sauce'
db    = require '../saucedb'

{Module  } = require '../module'
{TokenJar} = require '../../common/oauth'

# Module metadata
exports.name        = 'Debug'
exports.version     = '1.0'
exports.description = 'Debugging utilities'
exports.ignore      = 1
exports.locked      = 1

io.module '[Debug] Init'

oauth = new TokenJar Sauce.API.Twitch, Sauce.API.TwitchToken

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

        @regCmd 'dbg all', global, (user, args, bot) =>
            @cmdModules bot
            @cmdTriggers bot
            @cmdVars bot

        @regCmd 'dbg modules', global, (user, args, bot) =>
            @cmdModules bot

        @regCmd 'dbg triggers', global, (user, args, bot) =>
            @cmdTriggers bot

        @regCmd 'dbg vars', global, (user, args, bot) =>
            @cmdVars bot

        @regCmd 'dbg oauth', global, (user, args, bot) =>
            @cmdOauth bot

        @regCmd 'dbg commercial', global, (user, args, bot) =>
            @cmdCommercial bot


    cmdModules: (bot) ->
        @say bot, ("#{m.name}#{if not m.loaded then '[?]' else ''}" for m in @channel.modules).join(' ')


    cmdTriggers: (bot) ->
        @say bot, "Triggers for #{@channel.name}:"
        @say bot, "[#{t.oplevel}]#{t.pattern}" for t in @channel.triggers


    cmdVars: (bot) ->
        @say bot, "Variables for #{@channel.name}:"
        @say bot, "#{v.module} - #{k}" for k, v of @channel.vars.handlers


    cmdOauth: (bot) ->
        oauth.get '/user', (resp, body) =>
            io.debug body
            if body['display_name']?
                @say bot, "Authenticated as #{body['display_name']}"
            else
                @say bot, "Not authenticated."


    cmdCommercial: (bot) ->
        oauth.post "/channels/#{@channel.name}/commercial", (resp, body) =>
            @say bot, "Commercial: #{(resp?.headers?.status) ? resp.statusCode}"


    say: (bot, msg) ->
        bot.say "[Debug] #{msg}"


exports.New = (channel) -> new Debug channel

