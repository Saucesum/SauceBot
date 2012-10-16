SauceBot Structure
==================
SauceBot is designed as a flexible chat bot, capable of interfacing with many different chat services, while still providing a uniform interface to them all.

Table of Contents
----------------
* **[Client-Server Communication](#client-server-communication)**
   * [Client Messages](#client-messages)
   * [Server Responses](#server-responses)
* **[Configuration](#configuration)**
* **[Modules](#modules)**
    * [Requirements](#requirements)
    * [Localization](#localization)
    * [Other Options](#other-options)
* **[Message Handling](#message-handling)**
    * [Triggers](#triggers)
    * [Message Variables](#message-variables)

Client-Server Communication
---------------------------
There is always one instance of the SauceBot server. This server communicates with SauceBot clients, which in turn communicate with various chat services. Client-server data communication is encoded with JSON. Each client represents one instance of a chat service.

###Client Messages
A client can send various messages to the server; in JSON, each of these messages takes the form
```json
{
    "cmd": command,
    "data": data
}
```
where `command` specifies the type of message being sent, and `data` is the payload of the message. Note that, unlike the examples, newlines within a message are not permitted, but each message must be separated by a newline. There are currently four types of messages that the server recognizes, listed with the format of their data payload:
* `msg` is for standard messages, and is the primary means of communicating chat between the chat service and server through the client. When this command is received, the SauceBot instance, defined in [`saucebot`](src/server/saucebot.coffee), passes this message to [`channels`](src/server/channels.coffee), along with the set of functions that can be used to respond to the client.

```json
{
    "chan": channel,
    "user": user,
    "op": opLevel,
    "msg": message
}
```
`channel` is the channel where the message was issued, `user` is the user who sent the message, `opLevel` is the optional op level of the `user`, and `message` is the raw message itself.
* `pm` is used for private messages directed at the bot.

```json
{
    "user": user,
    "msg": message
}
```
`user` is the sender of the private message, and `message` is the contents of the message.
* `upd` is sent by the client to inform the server that it needs to reload/update some of its internal information, e.g., due to a change made in the web interface. At the moment, this command is only issued by the web interface.

```json
{
    "cookie": authCookie,
    "chan": channel,
    "type": type
}
```
`authCookie` is a cookie-based token that is used to authenticate the client to ensure that it has permission to have whatever update it is requesting done, `channel` is optional and can be used to limit the effects of the update to one channel, and `type` determines what is to be updated. The possible values for type are `'Users'`, which forces a reload of all users from the database; `'Channels'`, which reloads all of the channels; `'Help'` for indicating that help is being sent to `channel`; and if none of these, it is the name of a module which is to be reloaded.
* `get` is also sent by the client, currently, only the web interface, in order to retrieve information about the current state of the bot.

```json
{
    "cookie": authCookie,
    "chan": channel,
    "type": type
}
```
`authCookie` and `channel` are as in `upd`, but the available `type`s in this message are different - `'Users'` returns 

###Server Responses
As mentioned above, the server provides a number of functions to the `Channel` object in addition to the data received, so that the `Channel` can then respond appropriately to the client. These functions, listed with their arguments and the form of the data payload passed to the client, are as follows:
* `say(channel, message)` is used to instruct the client to send a message to the underlying chat service, on behalf of the bot.

```json
{
    "chan": channel,
    "msg": message
}
```
`channel` is the channel to send the message to, and `message` is the actual message to be sent.
* `ban(channel, user)` is used to have the client ban a given user from the channel.

```json
{
    "chan": channel,
    "user": user
}
```
As usual, `channel` is the channel being operated on, and `user` is the user to ban from the channel.
* `unban(channel, user)` is a complement to `ban`, used to remove a ban on a user in a given channel.

```json
{
    "chan": channel,
    "user": user
}
```
Like `ban`, `channel` is the channel that the ban is to be lifted in, and `user` is the user being unbanned.
* `timeout(channel, user, time)` asks the client to kick a user from a channel for a specified time.

```json
{
    "chan": channel,
    "user": user,
    "time": time
}
```
`channel` is of course the channel that the timeout is to take effect, `user` is the user being temporarily removed from the channel, and `time` is the time, in seconds, that the user cannot join the channel.
* `commercial(channel)` sends a message to the client that a commercial message should be displayed in the chat service.

```json
{
    "chan": channel
}
```
Here, `channel` is the channel that the commercial is to be displayed in.

There are a few other messages that the server can send to the client - `users`, `channels`, and `error`. `Channel` objects do not receive functions to send these messages; however, these messages are used by the server to notify the client of certain situations, and should be handled by any client implementation. The `error` message will only be emitted when an internal error occurs within the server. The data for `error` messages is formatted as follows:
```json
{
    "msg": err
}
```
where `err` is just a string indicating the nature of the error to the client. `users` messages are emitted in response to a `get` request with type `'Users'`, and the data payload of these messages will simply be a JSON array of the list of current users in the requested context, e.g.,
```json
["user1", "user2", "user3"]
```
`channels` messages are used to provide updates to the client on the list of currently monitored channels. At the moment, a client will only receive this channel list after having made a `get` request with the `'Channels'` type. The data payload of a `channels` message will be a JSON array of the channel objects, with each channel being represented by an object of the form
```json
{
    "id": id,
    "name": name,
    "status": status,
    "bot": botname
}
```
where `id` is the unique identifier used in the database to distinguish the channel, `name` is the name of the channel, `status` is the status of the channel, either `1` to indicate that the channel is enabled or `0` for it being disabled, and `botname` is the name of the bot responsible for that channel.

Configuration
-------------
The SauceBot server can be configured through a configuration file, `server.json`, in the directory `config` within the root SauceBot directory. As one might expect, this file is encoded with JSON, and has the following structure:
```json
{
    "name": botname,
    "port": port,
    
    "mysql": {
        "database": database,
        "username": username,
        "password": password
    },
    
    "logging": {
        "root": logdir
    }
}
```
In this file, `botname` is the name used internally to represent SauceBot, `port` is the port that the server listens for clients on, the `mysql` object contains the name of the MySQL database where SauceBot is stored (`database`) and the username and password needed to connect to the database (`username` and `password`, respectively), and the `logging` object specifies the root directory for storing log files created by SauceBot (`logdir`).

Modules
-------
A module is defined by a source file in the `modules` directory. Each channel has its own instance of a given module, so that module data can be channel specific, e.g., each channel can have its own list of chat filters, etc. To accomodate this, a channel object requests that a desired module be instantiated by [`module`](src/server/module.coffee). `module` registers a file listener to listen for any new modules being installed, and will also manually attempt to load a module with a given name from the filesystem. Once the module instance is created, it is tied to that channel.

###Requirements
Although `module` facilitates the creation of module instances, it does not actually define any modules. The only requirement imposed by `module` is that the loaded module has a `name`, `description`, and `version` attribute, and that it contains a `New(channel)` function that returns an instance appropriate for the channel it is being created for. However, there are other requirements of a module. Specifically, the module class must have both a `load()` and `unload()` function, which  are called, respectively, when the module is first loaded or reloaded, and when the module is being removed. It must also contain a `handle(user, message, bot)` function, which is called by its associated channel whenever the channel receives data. The handle function is passed the user who said the message received, the contents of the message, and the instance of the bot server.

###Localization
Each module also has the option to export its own custom string values which can be localized on a per-channel basis, not only for language reasons, but also to make each channel fun and unique. A module that exports a `strings` map for string key-names to default values will have these values inserted into the string table, under a default entry. Each channel can then provide these strings to modules via the `getString(module, key, args...)` function, or a module can access its own localized strings with its `str(key, args...)` function. In both cases, the `key` is the string used to identify the string being localized, and args are optional values that can be substituted in sequentially for values of the form `"@<number>@"`. Channel administrators can modify these strings from the default values, and `getString` will return these custom strings when available.

###Other Options
Two more options for a module are the `locked` and `ignore` exports. `locked` can be used to ensure that a module cannot be disabled, and `ignore` specifies whether new channels should not automatically enable the module. Like the `strings` export, these properties are automatically stored in the database when the module is loaded.

To summarize, here is an example of the framework of a module:
```coffeescript
# Basic information
exports.name        = 'MyModule'
exports.description = 'Basic module skeleton'
exports.version     = '1.0'

# Specifies that this module is always active
exports.locked      = true

# These are the custom strings that can be changed by an administrator of the channel
exports.strings     = {
    'string-1' : 'string 1 default value here'
    'string-2' : 'default value of string 2'
}

class MyModule
    constructor: (...) ->
        # This will typically store the channel instance, but this is not a requirement.
        ...
    load: ->
        # Handle all data loading and initialization here, bearing in mind, however,
        # that this method may be called again to reload data.
        # Initialization may also include registering handlers, etc.
        ...
    unload: ->
        # Release all resources acquired by this module, and unregister any handlers.
        # Also be sure to save any pending changes to the database.
        ...
    handle: (user, message, bot) ->
        # This is usually unnecessary, as to be explained,
        # but you can manually work with messsages here.
        ...
exports.New = (channel) ->
    # Create and return a new instance of the module.
    new MyModule ...
```

Message Handling
----------------
In order to implement its functionality, a module will typically require the cooperation of its channel. Modules have two ways of receiving data from the channel - they can wait for data on the `handle(user, message, bot)` function, or they can register a listener with the channel via the `Channel.register(trigger)` function. If the direct option of listening for data is taken, the module will handle all pattern matching, parsing, etc., on its own. In the case of registering a listener, however, a [`Trigger`](src/server/trigger.coffee) object is used.

###Triggers
A trigger is used for matching chat messages that take the form of `!<command> [options...]`. They are constructed via a call by the module to the channel's `register(args...)` function, which uses those arguments to call `trigger.buildTrigger(module, command, opLevel, execute)`, with `module` being the module creating the trigger; `command`, the base of the command for matching purposes; `opLevel`, a level from [`sauce.Level`](src/server/sauce.coffee), indicating the minimum permission level of the user who sent the message in order for any further processing to occur; and `execute(user, args, bot)`, a function that runs if the trigger conditions match, taking as parameters the user who sent the command, the arguments to the command, and the bot responsible for the message.

Triggers are designed such that in the case of commands with multiple forms, for example, `!timer` and `!timer start`, only the trigger for `!timer start` will execute when someone sends the message `"!timer start 123"`. The rule for trigger matching is that, if multiple triggers match a given message, the trigger with the most "parts" to it and a higher required permission level will execute over the others.

As an example, consider a command that enables users to set a timer to end after a given time, to stop a timer that has already been set, to check the status of a given timer, and to see all running timers. Suppose also that only moderator level users (`sauce.Level.Mod`) can start and stop timers. The following triggers would capture these messages:
* `!timer` and `!timer <name>` would be captured via

```coffeescript
    trigger.buildTrigger <module>, 'timer', sauce.Level.User, (user, args, bot) -> ...
```
where the execute function would check the number of arguments after "timer" to determine if the command is to show all timers, or a timer with a given name
* `!timer start <name>` would be captured with

```coffeescript
    trigger.buildTrigger <module>, 'timer start', sauce.Level.Mod, (user, args, bot) -> ...
```
where `args` would contain, as its first entry, the name argument to the command
* `!timer stop <name>` would similarly be represented with

```coffeescript
    trigger.buildTrigger <module>, 'timer stop', sauce.Level.Mod, (user, args, bot) -> ...
```
with `args` again containing the name of the timer to process
 
###Message Variables
In many case, it may be useful to store variables, which may even be dynamically determined, for use in user-created commands. By registering a variable with the `vars` of a channel, any message processed by that [`Vars`](src/server/vars.coffee) will have references to the variable in the message replaced with its evaluation. To register a variable, use the `Vars.register(var, handler)`, with `var` being the name of the variable to register, and `handler`, a function taking the user who submitted the command and the rest of the arguments to the variable, and calling a callback with the replacement string for the variable. Variables are signified in a string by `"$(name[ args...])"`.

Consider a variable `$(time)`. A module could register this variable via the command
```coffeescript
Vars.register 'time', (user, args, callback) -> ... # Call "callback" with result
```
Any message being processed by this `Vars` instance would have every occurrence of `$(time)` replaced with the time, as calculated by our handler function. This could allow custom messages (see [`Commands`](src/server/modules/commands.coffee)) to have embedded variables in them, and opens many new possibilities for interactivity.
