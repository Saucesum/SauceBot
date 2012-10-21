doc = """
SauceBot Server.

Usage:
  server <file> [-d | --debug | -v | --verbose | -q | --quiet]
  server -h | --help
  server --version
  server init <file>

Options:
  -h --help     Shows this screen.
  --version     Shows version.
  <file>        The config file to use [default ../../config/server.json].
  -d --debug    Enables debug messages.
  -v --verbose  Enable verbose output messages.
  -q --quiet    Disables all non-error messages.
"""

Sauce    = require './sauce'
question = require '../common/question'

fs       = require 'fs'
readline = require 'readline'
{docopt} = require 'docopt'

args = docopt(doc, version: Sauce.Version)


if args.init
    file = args['<file>']

    qs = new question.QuestionSystem()

    defaultPort = 28333

    qs.add 'Server', 'name', 'SauceBot'
    qs.add 'Server', 'port', "#{defaultPort}"
    
    qs.add 'MySQL', 'username', 'root'
    qs.add 'MySQL', 'password'
    qs.add 'MySQL', 'database', 'sauce'

    qs.add 'Logging', 'root', '/var/logs/saucebot/'

    console.log "\n###################################"
    console.log "#" + " Configuring SauceBot Server ... ".bold.magenta + "#"
    console.log "###################################\n"

    qs.start (data) ->
        {Server, MySQL, Logging} = data

        Server.port = parseInt(Server.port, 10) or defaultPort

        config = {
            name: Server.name
            port: Server.port
            mysql: MySQL
            logging: Logging
        }
        json = JSON.stringify(config, null, 4)
        
        # Write config file
        fs.writeFile file, json, 'utf8', (err) ->
            if err
                console.log "\nerror: could not write config file (#{err})".red.inverse
            else
                console.log "\nWrote configuration to #{file}"
                console.log 'Start server: ' + ("node server '#{file}'").magenta
                process.exit()

else
    # TODO: Load config file and start server
    1

