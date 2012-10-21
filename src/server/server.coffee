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
  -c --config   Where to generate a new config file.
"""

Sauce    = require './sauce'
question = require '../common/question'


readline = require 'readline'
{docopt} = require 'docopt'

args = docopt(doc, version: Sauce.Version)


#console.log args

if args.init
    file = args['<file>']

    qs = new question.QuestionSystem()

    qs.add 'Server', 'name', 'SauceBot'
    qs.add 'Server', 'port', '28333'
    
    qs.add 'MySQL', 'username', 'root'
    qs.add 'MySQL', 'password'
    qs.add 'MySQL', 'database', 'sauce'

    qs.add 'Logging', 'root', '/var/logs/saucebot/'

    console.log "\n###################################"
    console.log "#" + " Configuring SauceBot Server ... ".bold.magenta + "#"
    console.log "###################################\n"

    qs.start (data) ->
        {Server, MySQL, Logging} = data
        console.log "\n#{file}:"
        console.log JSON.stringify(data)
