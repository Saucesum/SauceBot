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

        @regCmd 'dbg reload', global, (user, args) =>
            unless (moduleName = args[0])?
                return @say "Usage: !dbg reload <module name>"

            @say "Reloading #{moduleName}"
            @channel.reloadModule moduleName

        @regCmd 'dbg unload', global, (user, args) =>
            unless (moduleName = args[0])?
                return @say "Usage: !dbg unload <module name>"

            db.removeChanData @channel.id, 'module', 'module', moduleName, =>
                @say "Unloading #{moduleName}"
                @channel.loadChannelModules()

        @regCmd 'dbg load', global, (user, args) =>
            unless (moduleName = args[0])?
                return @say "Usage: !dbg load <module name>"

            db.addChanData @channel.id, 'module', ['module', 'state'], [[moduleName, 1]], =>
               @say "Module #{moduleName} loaded"
               @channel.loadChannelModules()

        @regCmd 'dbg all', global, (user, args) =>
            @cmdModules()
            @cmdTriggers()
            @cmdVars()

        @regCmd 'dbg modules', global, (user, args) =>
            @cmdModules()

        @regCmd 'dbg triggers', global, (user, args) =>
            @cmdTriggers()

        @regCmd 'dbg vars', global, (user, args) =>
            @cmdVars()

        @regCmd 'dbg oauth', global, (user, args) =>
            @cmdOauth()

        @regCmd 'dbg commercial', global, (user, args) =>
            @cmdCommercial()


    cmdModules: ->
        @say ("#{m.name}#{if not m.loaded then '[?]' else ''}" for m in @channel.modules).join(' ')


    cmdTriggers: ->
        @say "Triggers for #{@channel.name}:"
        @say "[#{t.oplevel}]#{t.pattern}" for t in @channel.triggers


    cmdVars: ->
        @say "Variables for #{@channel.name}:"
        @say "#{v.module} - #{k}" for k, v of @channel.vars.handlers


    cmdOauth: ->
        oauth.get '/user', (resp, body) =>
            io.debug body
            if body['display_name']?
                @say "Authenticated as #{body['display_name']}"
            else
                @say "Not authenticated."


    cmdCommercial: ->
        oauth.post "/channels/#{@channel.name}/commercial", (resp, body) =>
            @say "Commercial: #{(resp?.headers?.status) ? resp.statusCode}"


exports.New = (channel) -> new Debug channel

