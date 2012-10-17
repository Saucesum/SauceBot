# Twitch.tv OAuth API Utilities

request = require 'request'
io      = require './ioutil'

# Base URL for all API requests
API_ROOT = 'https://api.twitch.tv/kraken'

# Redirect URL that must match the application page's redirect URL
REDIRECT_URI = 'http://localhost'

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
    # * clientID: the client_id of the application
    # * clientID: the client_secret of the application
    constructor: (@clientID, @clientSecret) ->
        # Any requests that could not be completed when requested
        # due to the token not being acquired yet
        @queue = []


    # Requests an OAuth token from the Twitch API, using the previously
    # supplied client_id and client_secret, and authenticating with the given
    # username, password, requesting the permissions specified in scope. The
    # possible permissions that can be requested can be found in the Scope
    # variable.
    #
    # * username: the username used for authenticating
    # * password: the password used for authenticating
    # * scope: a list of the permissions being requested in this token request
    requestToken: (username, password, scope) ->
        tokenRequest = {
            url     : API_ROOT + '/oauth2/token'
            method  : 'POST'
            form    : {
                grant_type    : 'password'
                client_id     : @clientID
                client_secret : @clientSecret
                username      : username
                password      : password
                scope         : scope.join ' '
            }
        }
        
        request tokenRequest, (err, resp, body) =>
            console.log resp
            return io.error err if err?
            return io.error "no token in response" unless body?.access_token?
            
            @token = body.access_token
            
            # Clear out any pending requests from the queue
            @queue.pop()() while @queue.length


    # Requests a resource from the API using a HTTP GET request. The name of
    # the resource always begins with a '/', and the response passed to the
    # callback is an object translated from the JSON response from the server.
    #
    # * resource: the resource being requested
    # * callback: a function taking the response object as an argument
    get: (resource, callback) ->
        action = =>
            getRequest = {
                url   : API_ROOT + resource
                qs    : {
                    oauth_token : @token
                }
                json  : true
            }
            
            request getRequest, (err, resp, body) ->
                console.log resp
                return io.error err if err?
                return io.error "no body in response for #{resource}" unless body?
                callback body
        
        # If the token has not yet been acquired, push this request to the
        # queue; otherwise, just execute it immediately
        if @token? then action() else @queue.push action


parseAuthenticityToken = (body) ->
    if (m = body.match(/<input.+?name\s*=\s*"authenticity_token".+?value\s*=\s*"([^"]+)"/))?
        return m[1]
    else
        return null


parseAccessToken = (response) ->
    return unless (loc = response.headers['location'])?

    if (m = loc.match(/access_token=([^&]+)&/))?
        return m[1]
    else
        return null


class OAuth
    constructor: (@clientID, @username, @password, @scopes) ->

        # List of queued requests waiting to be completed.
        @queue = []

        # Twitch API requires scopes to be separed by spaces
        scopeList = @scopes.join(' ')

        authorizeRequest = {
            url: "#{API_ROOT}/oauth2/authorize"
            qs : {
                redirect_uri : REDIRECT_URI
                client_id    : @clientID
                response_type: 'token'
                scope        : scopeList
            }
        }

        request authorizeRequest, (err, resp, body) =>
            if err?
                return io.error err
            authToken = parseAuthenticityToken body

            unless authToken?
                return io.error "authenticity_token not found"

            loginRequest = {
                method: 'POST'
                url   : "#{API_ROOT}/oauth2/allow"
                form  : {
                    utf8              : '\u2713'
                    authenticity_token: authToken
                    scope             : scopeList
                    response_type     : 'token'
                    client_id         : @clientID
                    redirect_uri      : REDIRECT_URI
                    'user[login]'     : @username
                    'user[password]'  : @password
                }
                followRedirect: false
            }

            request loginRequest, (err, resp, body) =>
                if err?
                    return io.error err

                @token ?= parseAccessToken resp
                console.log @token
                @authenticated = true
                @queue.pop()() while @queue.length
                

    perform: (location, method, data, callback) ->
        send = =>
            options = {
                url: API_ROOT + location
                qs :
                    oauth_token: @token
                method: method
                json  : true
            }
            if data? then options.body = data

            request options, (err, resp, body) ->
                callback body unless err?

        if @authenticated then send() else @queue.push send


exports.TokenJar = TokenJar
exports.OAuth = OAuth
