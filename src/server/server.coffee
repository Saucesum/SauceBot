doc = """
SauceBot Server.

Usage:
  server <file> [-d | --debug | -v | --verbose | -q | --quiet] [--clear-db]
  server -h | --help
  server --version
  server --config <file>

Options:
  -h --help     Shows this screen.
  --version     Shows version.
  --config      Configures the SauceBot server.
  <file>        The config file to use [default ./server.json].
  -d --debug    Enables debug messages.
  -v --verbose  Enable verbose output messages.
  -q --quiet    Disables all non-error messages.
  --clear-db    Clears the database before starting the server.
"""

question = require '../common/question'
graph    = require '../common/grapher'
config   = require './config'
Sauce    = require './sauce'
io       = require './ioutil'

fs       = require 'fs'
path     = require 'path'
readline = require 'readline'
{docopt} = require 'docopt'

args = docopt(doc, version: config.Version)

# Update output level fields
io.setLevel io.Level.Normal
io.setLevel io.Level.Debug   if args['--debug']
io.setLevel io.Level.Verbose if args['--verbose']
io.setLevel io.Level.Error   if args['--quiet']

file = args['<file>']

mkdirs = ->
    root = Sauce.Logging.Root
    fs.mkdirSync dir for dir in [
        path.join root
        path.join root, 'logs'
        path.join root, 'logs', 'channels'
    ] when not fs.existsSync dir


initGraph = ->
    if Sauce.Graphing.Host
        graph.init Sauce.Graphing.Host, Sauce.Graphing.Port, Sauce.Graphing.Name
        graph.count 'server.startup'

# Starts the server with the specified config file
startServer = ->
    Sauce.reload()
    console.log "Starting server #{Sauce.Server.Name} version #{Sauce.Version} ..."

    # Set up logging directories
    mkdirs()

    # Set up graphing
    initGraph()

    # Set up database
    db = require './saucedb'

    dropTables = args['--clear-db']
    db.setup dropTables, (err) ->
        io.error "Error setting up database: #{err}" if err?

    server = require './saucebot'


if args['--config']

    # Check whether we're editing or creating.
    try
        # File exists - we're editing.
        config.loadFile '.', file
    catch err
        # No such file - we're creating.


    qs = new question.QuestionSystem()

    qs.add 'Server', 'Name', config.Server.Name
    qs.add 'Server', 'Port', config.Server.Port
    
    qs.add 'MySQL', 'Username', config.MySQL.Username
    qs.add 'MySQL', 'Password', config.MySQL.Password
    qs.add 'MySQL', 'Database', config.MySQL.Database

    qs.add 'Logging', 'Root', config.Logging.Root

    qs.add 'Graphing', 'Host', config.Graphing.Host
    qs.add 'Graphing', 'Port', config.Graphing.Port
    qs.add 'Graphing', 'Name', config.Graphing.Name

    qs.add 'API', 'Twitch',      config.API.Twitch
    qs.add 'API', 'TwitchToken', config.API.TwitchToken
    qs.add 'API', 'LastFM',      config.API.LastFM
    qs.add 'API', 'Steam',       config.API.Steam

    qs.start 'Configuring SauceBot Server'.bold.magenta, (data) ->

        # Convert to JSON with 4 space indentation.
        json = JSON.stringify(data, null, 4)
        
        # Write config file
        fs.writeFile file, json, 'utf8', (err) ->
            if err
                console.log "\nerror: could not write config file (#{err})".red.inverse
                process.exit 1
            else
                console.log "\nWrote configuration to #{file}"
                console.log 'Start with: ' + ("node server '#{file}'").magenta
                process.exit 0

else
    try
        config.loadFile '.', file
    catch err
        console.log "Error loading configuration file \"#{file}\""
        console.log "Create with: " + ("node server --config '#{file}'").magenta
        process.exit 1

    startServer()

