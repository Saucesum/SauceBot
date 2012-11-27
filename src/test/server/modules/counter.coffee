# Start of unit testing for the Counter module.
#
# Copyright 2012 by Aaron Willey. All rights reserved

{
    CreateChannel, CreateChannels, DeleteChannels,
    CreateUser, CreateUsers, GrantUser, GrantUsers, DeleteUsers, Setup,
    Command, TestMultiple
} = require '../../testing'

Sauce = require '../../../server/sauce'

describe 'Counter', ->
    channels = {}
    users = {}

    before (done) ->
        Setup {
            channels: {
                loaded : {
                    modules : ['Counter']
                }
                modonly : {
                    modules : ['Counter']
                    modonly : 1
                }
            }
            users: {
                normal : {
                    name       : 'Joe'
                }
                mod : {
                    name       : 'CarlMod'
                    registered : true
                }
                admin : {
                    name       : 'PaulAdmin'
                    registered : true
                }
                owner : {
                    name       : 'FrankOwner'
                    registered : true
                }
                global : {
                    name       : 'Uber'
                    registered : true
                    global     : 1
                }
            }
        }, (cs, us) ->
            channels = cs
            all = (channel for name, channel of channels)
            users = us
            
            GrantUsers [
                {
                    channels : all
                    level    : Sauce.Level.Mod
                    users    : [users.mod]
                }
                {
                    channels : all
                    level    : Sauce.Level.Admin
                    users    : [users.admin]
                }
                {
                    channels : all
                    level    : Sauce.Level.Owner
                    users    : [users.owner]
                }
            ], done

    describe '!<counter> ...', (done) ->
        setCounter = Command '!counter =0'
        setResult = '[Counter] counter created and set to 0.'
        addCounter = Command '!counter +1'
        subtractCounter = Command '!counter -1'
        getCounter = Command '!counter'        
        unsetCounter = Command '!counter unset'
        unsetResult = '[Counter] counter removed.'

        it 'should not create a counter for normal users', (done) ->
            setCounter.in(channels.loaded).as(users.normal).waits done

        it 'should create a counter for moderators', (done) ->
            TestMultiple [
                (next) ->
                    setCounter.in(channels.loaded).as(users.mod).says setResult, next
                (next) ->
                    setCounter.in(channels.modonly).as(users.admin).says setResult, next
            ], done

        it 'should not be modified by normal users', (done) ->
            addCounter.in(channels.loaded).as(users.normal).waits done

        it 'should be changed by moderators', (done) ->
            TestMultiple [
                (next) ->
                    addCounter.in(channels.loaded).as(users.owner).says '[Counter] counter = 1', next
                (next) ->
                    addCounter.in(channels.loaded).as(users.global).says '[Counter] counter = 2', next
                (next) ->
                    subtractCounter.in(channels.loaded).as(users.mod).says '[Counter] counter = 1', next
            ], done

        it 'should not be viewable by users', (done) ->
            TestMultiple [
                (next) ->
                    getCounter.in(channels.loaded).as(users.normal).waits next
                (next) ->
                    getCounter.in(channels.modonly).as(users.normal).waits next
            ], done

        it 'should be viewable by moderators', (done) ->
            TestMultiple [
                (next) ->
                    getCounter.in(channels.loaded).as(users.owner).says '[Counter] counter = 1', next
                (next) ->
                    getCounter.in(channels.modonly).as(users.global).says '[Counter] counter = 0', next
            ], done
            
        it 'should be unset by moderators', (done) ->
            TestMultiple [
                (next) ->
                    unsetCounter.in(channels.loaded).as(users.admin).says unsetResult, next
                (next) ->
                    unsetCounter.in(channels.modonly).as(users.mod).says unsetResult, next
            ], done


    after (done) ->
        # Clean up the channels and users
        DeleteChannels (channel for name, channel of channels), ->
            DeleteUsers (user for name, user of users), done
