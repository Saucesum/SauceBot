# Unit Testing Utilities
# (part 2)
# 
# Copyright 2012 by Aaron Willey. All rights reserved

# It would be nice to use custom test configurations, at least to suppress the
# logging messages. This can be done in a hacky way.
io          = require '../server/ioutil'
io.setLevel io.Level.Error
config      = require '../server/config'

# This *has* to be before the others, otherwise channels will complain about no
# config file existing. The timing must be awful...
Sauce       = require '../server/sauce'
config.loadFile './config/', 'server.json'
Sauce.reload()

# Now it's safe to require our tools
{CallStack} = require '../common/util'
db          = require '../server/saucedb'
{Channel}   = require '../server/channels'
Users       = require '../server/users'


# Nevermind the ranting, it should all work internally, and it's the user's
# fault if they use it in a weird concurrent way. Anyway...
#
# Returns the lowest positive value in a column in a table that is not used by
# any other row, e.g., if there are rows containing field F with values 1, 2,
# and 4, this function will pass on the value of 3.
#
# * table   : the table to find the new id in
# * key     : the name of the column of the id
# * callback: a callback that takes the new id as an argument
nextId = (table, key, callback) ->
    db.getData table, (result) ->
        values = (parseInt(item[key], 10) for item in result).sort (a, b) -> (a - b)
        id = 1
        for value in values
            break unless value is id
            id++
        callback id
        

# Creates a channel using the specifed options, passing the new channel object
# to the given callback.
#
# * options : the options available are {
#       name    : the name of the channel
#       bot     : the name of the bot for the channel
#       modonly : whether the channel only responds to moderators
#       quiet   : whether the channel responds to no one
#       strings : a mapping of custom localized strings for this channel
#       modules : a list of module names to load for this channel
#   }
# * callback: the function to pass the new channel object to
CreateChannel = (options, callback) ->
    nextId 'channel', 'chanid', (id) ->
        defaults = {
            # It's important to keep the channel names unique, otherwise the
            # database will say mean things
            name    : 'TestChannel' + id
            bot     : 'TestBot'
            modonly : 0
            quiet   : 0
            strings : {}
            modules : []
        }

        options[k] ?= v for k, v of defaults

        {name, bot, modonly, quiet, strings, modules} = options

        # Create a call stack that ends with creating the new channel and
        # passing it to a callback
        stack = new CallStack ->
            channel = new Channel {
                chanid : id
                name   : name
                status : 1
                bot    : bot
            }

            # Tack on a remove function to the channel, so that we can reclaim
            # (some) of its resources in the database. The callback is used to
            # inform the caller when the removal is complete.
            channel.remove = (callback) ->
                removeStack = new CallStack callback
                
                removeStack.add (next) ->
                    db.clearChanData id, 'channel', next
                removeStack.add (next) ->
                    db.clearChanData id, 'channelconfig', next
                removeStack.add (next) ->
                    db.clearChanData id, 'strings', next
                removeStack.add (next) ->
                    db.clearChanData id, 'module', next

                removeStack.start()
                
            # Now hand off the channel
            callback channel
        
        # Tons of database initialization stuff for the channel, all which has
        # to be done asynchronously...
        # In summary, we clear the channel data for our channel, just in case
        # of anything leftover, and then fill it based on the provided options.

        stack.add (next) ->
            db.clearChanData id, 'channel', ->
                db.getData 'channel', (result) ->
                    next()
        
        stack.add (next) ->
            db.addChanData id, 'channel', ['name', 'status', 'bot'], [[
                name
                1
                bot
            ]], ->
                db.getData 'channel', (result) ->
                    next()

        stack.add (next) ->
            db.clearChanData id, 'channelconfig', next
        
        stack.add (next) ->
            db.addChanData id, 'channelconfig', ['modonly', 'quiet'], [[
                modonly
                quiet
            ]], next

        stack.add (next) ->
            db.clearChanData id, 'strings', next

        if Object.keys(strings).length
            stack.add (next) ->
                db.addChanData 'strings', ['key', 'value'], ([
                    key
                    value
                ] for key, value of strings), next

        stack.add (next) ->
            db.clearChanData id, 'module', next
        
        if modules?.length
            stack.add (next) ->
                db.addChanData id, 'module', ['module', 'state'], ([
                    module
                    1
                ] for module in modules), next

        # Start up the stack, and hope it flies.
        stack.start()
    

# Creates multiple channels with specified names and options, passing them all
# at once to a callback.
#
# * channels: a map of channel names to options for their creation; refer to
#             the Channel function for the available options
# * callback: a callback that is passed a map of channel names to their
#             appropriate instantiated channel objects
CreateChannels = (channels, callback) ->
    result = {}
    stack = new CallStack ->
        callback result

    for name, options of channels
        do (name, options) ->
            stack.add (next) ->
                CreateChannel options, (channel) ->
                    result[name] = channel
                    next()

    stack.start()


# Deletes the given channels from the database, as best as it can. Note that
# this function cannot delete module data for a channel.
#
# * channels: the array of channel objects to delete
# * callback: a callback to invoke when all of the channels are deleted
DeleteChannels = (channels, callback) ->
    stack = new CallStack callback
    for channel in channels
        do (channel) ->
            stack.add (next) ->
                channel.remove next
    stack.start()


# Creates a user object given a set of parameters.
#
# * options: {
#       name       : the username
#       op         : the permission level of the user
#       global     : whether the user is a global admin
#       registered : if the user is registered in the database
#   }
# = a user object for passing to channels
CreateUser = (options, callback) ->
    user = {
        name   : options.name ? 'TestUser'
        op     : options.op and 1
        global : options.global and 1
        remove : (cb) -> cb()
    }
    return callback user unless options.registered

    db.getData 'users', (users) ->
        users = (u.username for u in users)
        name = user.name
        i = 0
        name = user.name + i++ while name in users

        nextId 'users', 'userid', (id) ->
            db.addData 'users', ['userid', 'username', 'global'], [[id, name.toLowerCase(), user.global]], (err, results) ->
                user.id = id
                user.remove = (cb) ->
                    db.query "DELETE FROM users WHERE userid = #{user.id}", ->
                        db.query "DELETE FROM moderator WHERE userid = #{user.id}", ->
                            cb()
                Users.load ->
                    callback user


# Creates multiple users using a given specification, passing the result to a
# callback function.
#
# * users   : a map of arbitrary names to user option defintions; the names used
#             as the keys only matter to the test creator
# * callback: a function that takes as its argument a map of the names defined
#             in the users parameter to actual user objects
CreateUsers = (users, callback) ->
    result = {}
    stack = new CallStack ->
        callback result

    for name, options of users
        do (name, options) ->
            stack.add (next) ->
                CreateUser options, (user) ->
                    result[name] = user
                    next()

    stack.start()


# Gives the user defined by the given object permissions in a specified channel;
# once this is finished, a callback is invoked.
#
# * user     : a user object, created with one of the CreateUser functions
# * channel  : a channel object that represents the channel where the user is
#              receiving permissions
# * level    : the permissions level to grant the user
# * callback : a no-argument callback for notifying the caller when the
#              operation is completed
GrantUser = (user, channel, level, callback) ->
    return callback() unless user.id
    db.addChanData channel.id, 'moderator', ['userid', 'level'], [[user.id, level]], ->
        Users.load ->
            callback()


# Takes a specification of permissions to grant to various users and applies
# them, using a callback to inform the caller when this is done.
#
# * permissions: an array of permission declarations, each having the form
#                {
#                    channels : C
#                    level    : L
#                    users    : U
#                }
#                where C is an array of channels, L is the permission to be
#                applied, and U is an array of users. Each item with C, L, and U
#                causes all users in U to receive permission level L in channel
#                C.
# * callback  : a simple callback that is invoked when the operation is done
GrantUsers = (permissions, callback) ->
    stack = new CallStack callback

    for permission in permissions
        for channel in permission.channels
            for user in permission.users
                do (user, channel, permission) ->
                    stack.add (next) ->
                        GrantUser user, channel, permission.level, next

    stack.start()
    

# Removes user definitions and permissions from the database. This function
# simply takes user object created with this utility and invokes their remove()
# functions, handling the callbacks automatically.
#
# * users   : an array of user objects to delte
# * callback: a callback that is called once the users are deleted
DeleteUsers = (users, callback) ->
    stack = new CallStack callback
    for user in users
        do (user) ->
            stack.add (next) ->
                user.remove next
    stack.start()


# A class to facilitate concise command testing.
class CommandTester

    # Creates a new command tester.
    #
    # * command: the command that is being tested
    constructor: (@command) ->


    # Sets the channel that the command is to be tested in.
    #
    # * channel: the channel to use for testing
    # = the command tester
    in: (@channel) ->
        this


    # Sets the user that is using the command in the test.
    #
    # * user: the user who attempt to use the command
    # = the command tester
    as: (@user) ->
        this
        

    # Waits for a specified time and throws an error if the bot atttempts to say
    # anything before that time has passed.
    #
    # * timeout: the amount of time to wait before continuing (default 500ms)
    # * done   : a no-argument callback to be called if the wait was successful
    waits: (timeout, done) ->
        return unless @channel and @user
        [timeout, done] = [500, timeout] unless done?
        bot = {
            say: (message) ->
                throw new Error "It said #{message} (expected nothing)"
        }
        @channel.handle {
            user : @user.name.toLowerCase()
            op   : @user.op
            msg  : @command
        }, bot
        setTimeout ->
            # Set the say method to do nothing, just in case it's called later
            bot.say = ->
            done()
        , timeout


    # Requires that the bot say a specified message, calling a completion
    # callback only if the bot says that message, and throwing an error if it
    # says anything else.
    #
    # * expected: the message that the bot should say
    # * done    : the no-argument completion callback
    says: (expected, done) ->
        return unless @channel and @user
        bot = {
            say: (message) ->
                throw new Error "It said #{message} (expected #{expected})" unless message is expected
                done()
        }
        @channel.handle {
            user : @user.name.toLowerCase()
            op   : @user.op
            msg  : @command
        }, bot
    

# A simple convenience method for creating new command testers.
#
# * command: the string of the full command to test
# = the appropriate command tester
Command = (command) ->
    new CommandTester command


# A convenience method for taking multiple test functions that take a single
# callback as an argument that they call when their test is complete, and making
# one single test unit that calls a given final callback when all of the tests
# have finished. This could probably be improved on to make usage simpler.
#
# * tests   : a list of test functions that take a function to call when they
#             complete as an argument
# * callback: a function to call when all of the tests have completed
TestMultiple = (tests, callback) ->
    stack = new CallStack callback
    stack.add test for test in tests
    stack.start()


exports.CreateChannel  = CreateChannel
exports.CreateChannels = CreateChannels
exports.DeleteChannels = DeleteChannels
exports.CreateUser     = CreateUser
exports.CreateUsers    = CreateUsers
exports.GrantUser      = GrantUser
exports.GrantUsers     = GrantUsers
exports.DeleteUsers    = DeleteUsers
exports.Command        = Command
exports.TestMultiple   = TestMultiple