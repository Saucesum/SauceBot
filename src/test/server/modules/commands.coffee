# Start of unit testing for the Commands module.
#
# Copyright 2012 by Aaron Willey. All rights reserved

{
    SetupModule, CleanupModule,
    Command, TestMultiple
} = require '../../testing'

Sauce = require '../../../server/sauce'

# This section can certainly be improved, but there are multiple ways of doing
# so. The problem is that that actual unit test functions, produced by
#     set.in(...).as(...).<something>
# are not evaluated until the callback from SetupModule is invoked. Because of
# this, Mocha thinks that all of the tests have completed and ignores the ones
# that we want to do once we get the channel and users from SetupModule. One
# rather hacky way of working around this is to wrap the entire SetupModule
# block with an 'it' containing a callback function that is invoked only after
# the unit tests have been created, i.e., the method calls are completed.
#
# We can also use a 'before' and 'it' following the SetupModule to force it to
# run the test creation code, but this isn't pretty either. All of the other
# combinations I could think of don't seem to work. Ideally, there could be a
# version of 'describe' that passes a 'done' function, but this doesn't exist.
#
# In general, I like the current layout after the SetupModule call - it seems
# concise and easy to modify, but it would be nice to figure out this top-level
# call somehow, it's just weird at the moment.
it 'Created channel with Commands module', (done) ->
    SetupModule 'Commands', (T) ->
        describe 'Commands', ->
            command = 'hello'
            message = 'Hello World!'
            
            describe "!set #{command} #{message}", ->
                set = Command "!set #{command} #{message}"
                setMessage = 'Command set: ' + command

                it 'should not set the command for normal users',
                    TestMultiple [
                        set.in(T.Channel).as(T.Users.User).waits()
                        set.in(T.Channel).as(T.Users.Registered).waits()
                    ]

                it 'should set the !hello command for privileged users',
                    TestMultiple [
                        set.in(T.Channel).as(T.Users.Op).says setMessage                
                        set.in(T.Channel).as(T.Users.Mod).says setMessage
                        set.in(T.Channel).as(T.Users.Admin).says setMessage
                        set.in(T.Channel).as(T.Users.Owner).says setMessage
                        set.in(T.Channel).as(T.Users.Global).says setMessage                
                    ]
                    
            describe '!' + command, ->
                hello = Command '!' + command
                
                it 'should respond with \'' + message + '\' for all users',
                    TestMultiple [
                        hello.in(T.Channel).as(T.Users.User).says message
                        hello.in(T.Channel).as(T.Users.Registered).says message
                        hello.in(T.Channel).as(T.Users.Op).says message                
                        hello.in(T.Channel).as(T.Users.Mod).says message
                        hello.in(T.Channel).as(T.Users.Admin).says message
                        hello.in(T.Channel).as(T.Users.Owner).says message
                        hello.in(T.Channel).as(T.Users.Global).says message                
                    ]

            after (done) ->
                CleanupModule T, done

        done()
