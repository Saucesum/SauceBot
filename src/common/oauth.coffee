# Twitch.tv OAuth API Utilities

request = require 'request'
io      = require './ioutil'
util    = require 'util'

# Base URL for all API requests
API_ROOT = 'https://api.twitch.tv/kraken'

# Redirect URL that must match the application page's redirect URL
REDIRECT_URI = 'http://saucesum.no-ip.org/saucebot/'

# API Scopes
exports.Scope = Scope =
    User:
        # Read access to non-public user information, such as email address.
        Read    : 'user_read'
        # Access to followed streams.
        Followed: 'user_followed'

        Blocks:
            # Ability to ignore or unignore on behalf of a user.
            Edit: 'user_blocks_edit'
            # Read access to a user's list of ignored users.
            Read: 'user_blocks_read'

    Channel:
        # Read access to non-public channel information, including email address and stream key.
        Read      : 'channel_read'
        # Write access to channel metadata (game, status, other metadata).
        Editor    : 'channel_editor'
        # Access to trigger commercials on channel.
        Commercial: 'channel_commercial'
        # Ability to reset a channel's stream key.
        Stream    : 'channel_stream'


# A TokenJar stores an authentication token acquired from the Twitch API, and
# then allows for resource requests to be made to the API using the token.
class TokenJar


    # Constructs a new instance of a TokenJar. Note that the instance returned
    # is not initialized and has not yet requested an authentication token.
    #
    # * clientID : the client_id of the application.
    # * authToken: the active auth token.
    constructor: (@clientID, @authToken) ->
        0xCAFEBABE # Because every class needs some Java love.


    # Requests a resource from the API using a HTTP GET request. The name of
    # the resource always begins with a '/', and the response passed to the
    # callback is the response object and the body, which may be null.
    #
    # * resource: the resource being requested.
    # * callback: a function taking the response object and body as arguments.
    get: (resource, callback) ->
        getRequest = {
            url   : API_ROOT + resource
            method: 'GET'
            json  : true

            qs    : { oauth_token: @authToken }
        }
        
        request getRequest, (err, resp, body) =>
            io.debug "[GET #{resource}] #{resp.headers.status}"
            return io.error err if err?

            @process resp, body, callback


    # Requests a resource from the API using a HTTP POST request. The name of
    # the resource always begins with a '/', and the response passed to the
    # callback is the response object and the body, which may be null.
    #
    # * resource: the resource being requested.
    # * callback: a function taking the response object and body as arguments.
    post: (resource, callback) ->
        postRequest = {
            url   : API_ROOT + resource
            method: 'POST'

            form  : { oauth_token: @authToken }
            qs    : { oauth_token: @authToken }
        }

        request postRequest, (err, rep, body) =>
            io.debug "[POST #{resource}] #{resp.headers.status}"
            return io.error err if err?

            @process resp, body, callback


    process: (resp, body, callback) ->
        if body? and typeof body isnt 'object'
            body = @parseJSON body

        callback resp, body
            

    # Attempts to parse JSON, ignoring any errors thrown.
    #
    # * data: the string to parse.
    # = object if successful, null otherwise.
    parseJSON: (data) ->
        try
            return JSON.parse data
        catch err
            # Not JSON
            return null
             
              
exports.TokenJar = TokenJar
              
