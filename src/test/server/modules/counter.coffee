# Start of unit testing for the Counter module.
#
# Copyright 2012 by Aaron Willey. All rights reserved

{
    SetupModule, CleanupModule
    Command, TestMultiple
} = require '../../testing'

Sauce = require '../../../server/sauce'

it 'Created channel with Counter module', (done) ->
    SetupModule 'Counter', (T) ->
        describe 'Counter', ->
            setCounter = '!counter =0'
            addCounter = '!counter +1'
            subtractCounter = '!counter -1'
            viewCounter = '!counter'
            unsetCounter = '!counter unset'
            
            describe setCounter, ->
                set = Command setCounter
                setResponse = '[Counter] counter created and set to 0.'
                currentResponse = '[Counter] counter = 0'

                it 'should not do anything for normal users',
                    TestMultiple [
                        set.in(T.Channel).as(T.Users.User).waits()
                        set.in(T.Channel).as(T.Users.Registered).waits()
                    ]
                
                it 'should create a counter starting at 0 for privileged users',
                    set.in(T.Channel).as(T.Users.Op).says setResponse

                it 'should set the counter if it already exists',
                    TestMultiple [
                        set.in(T.Channel).as(T.Users.Mod).says currentResponse
                        set.in(T.Channel).as(T.Users.Admin).says currentResponse
                        set.in(T.Channel).as(T.Users.Owner).says currentResponse
                        set.in(T.Channel).as(T.Users.Global).says currentResponse
                    ]

            describe addCounter, ->
                add = Command addCounter

                it 'should not affect the counter for normal users',
                    TestMultiple [
                        add.in(T.Channel).as(T.Users.User).waits()
                        add.in(T.Channel).as(T.Users.Registered).waits()
                    ]

                it 'should increment the counter for privileged users',
                    TestMultiple [
                        add.in(T.Channel).as(T.Users.Op).says '[Counter] counter = 1'
                        add.in(T.Channel).as(T.Users.Mod).says '[Counter] counter = 2'
                        add.in(T.Channel).as(T.Users.Admin).says '[Counter] counter = 3'
                        add.in(T.Channel).as(T.Users.Owner).says '[Counter] counter = 4'
                        add.in(T.Channel).as(T.Users.Global).says '[Counter] counter = 5'
                    ]

            describe subtractCounter, ->
                subtract = Command subtractCounter

                it 'should not affect the counter for normal users',
                    TestMultiple [
                        subtract.in(T.Channel).as(T.Users.User).waits()
                        subtract.in(T.Channel).as(T.Users.Registered).waits()
                    ]

                it 'should decrement the counter for privileged users',
                    TestMultiple [
                        subtract.in(T.Channel).as(T.Users.Op).says '[Counter] counter = 4'
                        subtract.in(T.Channel).as(T.Users.Mod).says '[Counter] counter = 3'
                        subtract.in(T.Channel).as(T.Users.Admin).says '[Counter] counter = 2'
                        subtract.in(T.Channel).as(T.Users.Owner).says '[Counter] counter = 1'
                        subtract.in(T.Channel).as(T.Users.Global).says '[Counter] counter = 0'
                    ]

            describe viewCounter, ->
                view = Command viewCounter
                viewResponse = '[Counter] counter = 0'

                it 'should not be accessible by normal users',
                    TestMultiple [
                        view.in(T.Channel).as(T.Users.User).waits()
                        view.in(T.Channel).as(T.Users.Registered).waits()
                    ]

                it 'should show the current value for privileged users',
                    TestMultiple [
                        view.in(T.Channel).as(T.Users.Op).says viewResponse
                        view.in(T.Channel).as(T.Users.Mod).says viewResponse
                        view.in(T.Channel).as(T.Users.Admin).says viewResponse
                        view.in(T.Channel).as(T.Users.Owner).says viewResponse
                        view.in(T.Channel).as(T.Users.Global).says viewResponse
                    ]

            describe unsetCounter, ->
                unset = Command unsetCounter
                unsetResponse = '[Counter] counter removed.'
                view = Command viewCounter

                it 'should do nothing for normal users',
                    TestMultiple [
                        unset.in(T.Channel).as(T.Users.User).waits()
                        unset.in(T.Channel).as(T.Users.Registered).waits()
                    ]

                it 'should remove the counter for privileged users',
                    unset.in(T.Channel).as(T.Users.Op).says unsetResponse

                it 'should make the counter unavailable',
                    TestMultiple [
                        view.in(T.Channel).as(T.Users.Mod).waits()
                        view.in(T.Channel).as(T.Users.Admin).waits()
                        view.in(T.Channel).as(T.Users.Owner).waits()
                        view.in(T.Channel).as(T.Users.Global).waits()
                    ]

            after (done) ->
                CleanupModule T, done

        done()
