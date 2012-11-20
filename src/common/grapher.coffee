# Graphing utility
# Requires statd and graphite

# Node.js
udp = require 'dgram'
col = require 'colors'

# SauceBot
io  = require './ioutil'


# StatsD server connection.
class StatsD

    # Constructs a new StatsD socket handler.
    # * host  : The hostname of the StatsD server.
    # * port  : The port of the StatsD server.
    # * bucket: The root bucket-name to use.
    constructor: (@host, @port, @bucket) ->
        @connect()
        @messages = 0


    # Creates the UDP connection.
    connect: ->
        @close()
        @client = udp.createSocket 'udp4'
        io.socket "Connected to StatsD on " + "#{@host}:#{@port}".bold


    # Closes the active connection.
    close: ->
        @client?.close()
        @client = null
        io.socket "Disconnected from StatsD"


    # Sends a UDP message to the StatsD server if connected.
    # * tag : The message's label.
    # * val : The message's value.
    # * type: The type of the message as a string.
    send: (tag, val, type) ->
        unless @client?
            # Not connected. Ignore request.
            return

        msg = @createMessage tag, val, type
        @client.send msg, 0, msg.length, @port, @host, ->
            @messages++


    # Creates a new StatsD-type message.
    # * tag  : The sub-name of the message bucket.
    # * value: The value to store.
    # * type : The type of the message as a string.
    #          e.g. 'c', 'g', 'ms'.
    createMessage: (tag, value, type) ->
        new Buffer "#{@bucket}#{tag}:#{value}|#{type}"


# StatsD instance object
statsd = null

# Initializes the StatsD client.
init = (host, port, bucket) ->
    # First close any existing connections.
    stop()

    # Then create a new connection object.
    statsd = new StatsD host, port, bucket


# Stops any active StatsD clients.
stop = ->
    statsd?.close()


# Sends a message to the StatsD client if connected.
send = (tag, val, type) ->
    statsd?.send tag, val, type


# Sends a counter message.
count = (name, value = 1) ->
    send name, value, 'c'


# Sends a timing message.
time = (name, value = 1) ->
    send name, value, 'ms'


# Sends a gauge messag.
gauge = (name, value) ->
    send name, value, 'g'

exports[k] = v for k, v of {
    # Control
    init: init
    stop: stop

    # Messages
    count: count
    time : time
    gauge: gauge
}
