# Start of unit testing for the Commands module.
#
# Copyright 2012 by Aaron Willey. All rights reserved

{
    CreateChannel, CreateChannels, DeleteChannels,
    CreateUser, CreateUsers, GrantUser, GrantUsers, DeleteUsers, Setup,
    Command, TestMultiple
} = require '../../testing'

Sauce = require '../../../server/sauce'

describe 'Commands', ->
    channels = {}
    users = {}

    before (done) ->
        Setup {
            channels: {
                loaded : {
                    modules : ['Commands']
                }
                empty : { }
                modonly : {
                    modules : ['Commands']
                    modonly : 1
                }
            }
            users: {
                normal : {
                    name       : 'Joe'
                }
                mod : {
                    name       : 'CarlMod'
                    op         : 1
                }
                admin : {
                    name       : 'PaulAdmin'
                    op         : 1
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
                    level    : Sauce.Level.Admin
                    users    : [users.admin]
                }
                {
                    channels : all
                    level    : Sauce.Level.Owner
                    users    : [users.owner]
                }
            ], done
                
    describe '!set', ->
        # Set up the testers and the expected responses
        useMessage = 'Hello World!'
        set = Command '!set hello ' + useMessage
        setMessage = 'Command set: hello'
        hello = Command '!hello'

        # Create the actual test cases
        it 'should not set a command for normal users', (done) ->
            set.in(channels.loaded).as(users.normal).waits done

        it 'should set the command for users with permissions', (done) ->
            TestMultiple [
                (next) ->
                    set.in(channels.loaded).as(users.mod).says setMessage, next
                (next) ->
                    set.in(channels.loaded).as(users.admin).says setMessage, next
                (next) ->
                    set.in(channels.modonly).as(users.owner).says setMessage, next
            ], done

        it 'should do nothing if the module is not loaded', (done) ->
            set.in(channels.empty).as(users.normal).waits done

        it 'should create a command called !hello', (done) ->
            TestMultiple [
                (next) ->
                    hello.in(channels.loaded).as(users.normal).says useMessage, next
                (next) ->
                    hello.in(channels.loaded).as(users.global).says useMessage, next
            ], done

        it 'should only respond to mods in a mod-only channel', (done) ->
            TestMultiple [
                (next) ->
                    hello.in(channels.modonly).as(users.normal).waits next
                (next) ->
                    hello.in(channels.modonly).as(users.mod).says useMessage, next
            ], done

    after (done) ->
        # Clean up the channels and users
        DeleteChannels (channel for name, channel of channels), ->
            DeleteUsers (user for name, user of users), done
