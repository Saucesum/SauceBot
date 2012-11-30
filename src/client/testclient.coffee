doc = """
SauceBot Test Client

Usage:
    testclient <host> <port> <chan> <user>
    testclient -h | --help

Options:
    -h --help   Shows this message.
    <host>      Hostname of SauceBot server.
    <port>      Port of SauceBot server.
    <chan>      Channel to connect to.
    <user>      User to connect as.
"""

color    = require 'colors'
term     = require 'readline'
{docopt} = require 'docopt'

io     = require '../common/ioutil'
Socket = require '../common/socket'

io.setLevel(io.Level.All)

conf = docopt(doc)

ip   = conf['<host>']
port = conf['<port>']
chan = conf['<chan>']
name = conf['<user>']

port = parseInt port, 10

cli = new Socket.Client ip, port
cli.on 'say', (data) ->
    {msg} = data
    console.log "[#{data.chan.blue}] #{msg}"
    rl.prompt()

cli.on 'channels', (data) ->
    elems = []
    for c in data
        elems.push (if c.status then "#{c.name.blue.bold}##{c.id}" else "#{c.name.red}##{c.id}")
    console.log "\nConnected ... [#{'Channels'.green}]:", elems.join(', ')
    rl.prompt()

cli.on 'connect', ->
    cli.emit 'register',
        type: 'chat'
        name: 'TestClient'

cli.on 'users', (data) ->
    console.log data
    
cli.on 'error', (data) ->
    {msg} = data
    io.error msg

cli.on 'raw', (line) ->
    io.debug "\n" + line

cli.on 'timeout', (data) ->
    {chan, user, time} = data
    io.debug "TIMEOUT #{chan}: #{user} for #{time} seconds"

cli.on 'ban', (data) ->
    {chan, user} = data
    io.debug "BAN #{chan}: #{user}"

cli.on 'unban', (data) ->
    {chan, user} = data
    io.debug "UNBAN #{chan}: #{user}"

rl = term.createInterface process.stdin, process.stdout, (line) ->
    if (/^\/c/.test line)
        return [["/channel "], line]
    if (/^\/u/.test line)
        return [["/user "], line]
    if (/^\/r/.test line)
        return [["/reload "], line]
    if (/^\//.test line)
        return [["/channel ", "/user ", "/reload "], line]
    return [["/"], line]
    
rl.setPrompt name + '@' + chan + '> '
rl.prompt()

rl.on 'line', (line) ->
    if m = /^\/channel\s+([-a-zA-Z0-9_]+)/.exec(line)
        chan = m[1]
        rl.setPrompt name + '@' + chan + '> '

    else if m = /^\/user\s+([-a-zA-Z0-9_]+)/.exec(line)
        name = m[1]
        rl.setPrompt name + '@' + chan + '> '
        
    else if m = /^\/reload\s+([a-zA-Z_0-9]+)\s+([a-zA-Z_0-9]+)/.exec(line)
        chan = m[1]
        name = m[2]
        cli.emit 'upd'
            cookie: '...'
            type  : name
            chan  : chan

    else if m = /^\/get\s+([a-zA-Z_0-9]+)/.exec line
        type = m[1]
        cli.emit 'get',
            cookie: '...'
            chan  : chan
            type  : type
        
    else
        cli.emit 'msg',
            chan: chan
            user: name
            msg : line

    rl.prompt()

rl.on 'close', ->
    console.log "\n"
    process.exit 0

