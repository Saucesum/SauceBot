doc = """
SauceBot Server.

Usage:
  server <file> [-d | --debug | -v | --verbose | -q | --quiet]
  server -h | --help
  server --version
  server init [-c <file> | --config <file>]

Options:
  -h --help     Shows this screen.
  --version     Shows version.
  <file>        The config file to use [default ../../config/server.json].
  -d --debug    Enables debug messages.
  -v --verbose  Enable verbose output messages.
  -q --quiet    Disables all non-error messages.
  -c --config   Where to generate a new config file.
"""

Sauce = require './sauce'

{docopt} = require 'docopt'


args = docopt(doc, version: Sauce.Version)

console.log args
