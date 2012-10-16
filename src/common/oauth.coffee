request = require 'request'
    
apiroot = 'https://api.twitch.tv/kraken'
everything = 'user_read user_blocks_edit user_blocks_read user_followed channel_read channel_editor channel_commercial channel_stream'
stupidRedirect = 'http://localhost'

class OAuth
    constructor: (@clientID, @username, @password) ->
        @queue = []
        initial = "#{apiroot}/oauth2/authorize?redirect_uri=#{stupidRedirect}&client_id=#{clientID}&response_type=token&scope=#{everything}"
        request initial, (error, response, body) =>
            return if error
            superSecretToken = body.match(/<input.+?name\s*=\s*"authenticity_token".+?value\s*=\s*"([^"]+)"/)[1]
            login = {
                'method': 'POST',
                'url': "#{apiroot}/oauth2/allow",
                'form': {
                    'utf8': '\u2713',
                    'authenticity_token': superSecretToken,
                    'scope': everything,
                    'response_type': 'token',
                    'client_id': clientID,
                    'redirect_uri': stupidRedirect,
                    'user[login]': username,
                    'user[password]': password
                },
                'followRedirect': false
            }
            request login, (error, response, body) =>
                return  if error
                @token = response.headers['location'].match(/access_token=([^&]+)&/)[1]
                @authenticated = true
                while @queue.length
                    @queue.pop()()
            
    perform: (location, method, data, callback) ->
        send = =>
            options = {
                'url': "#{apiroot}#{location}?oauth_token=#{@token}",
                'method': method,
                'json': true
            }
            if data? then options.body = data
            request options, (error, response, body) ->
                callback body if !error
        if @authenticated then send() else @queue.push send

exports.OAuth = OAuth
