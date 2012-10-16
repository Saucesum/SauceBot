# Twitch.tv OAuth API Utilities

request = require 'request'
io      = require './ioutil'

# Base URL for all API requests
API_ROOT = 'https://api.twitch.tv/kraken'

# Redirect location required but not needed unless
# dealing with client account authorization.
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
                redirect_uri : REDIRECT_URL
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

exports.OAuth = OAuth
