SauceBot Structure
==================
There is always one instance of the SauceBot server. This server communicates with SauceBot clients, which in turn communicate with various chat services. Client-server data communication is encoded with JSON. Each client represents one instance, or channel, of a chat service. A client can send various messages to the server, notably, 'msg' for messages, 'pm' for private messages, 'upd' for updates, and 'get' for requests from the client. 'upd' and 'get' are used in the web interface, and are covered elsewhere. 'pm' is only handled in the case of a private message from staff at the moment and is simply logged by the server. This leaves 'msg' - the main form of communication between the client and server. When a message is received from a client representing a specific channel, the SauceBot instance, defined in `saucebot`, passes this message to `channels`, along with the set of functions that can be used to respond to the client.

Before all of this can happen though, everything must be initialized from the database. From `saucebot`, `users` and `channels` are called to load their data - respectively, the list of registered users and their associated permissions in each channel, and the channel data for each channel. The channel data is more complex - it not only includes information such as name, status, id, but each channel can also have modules associated with it.

A module is defined by a .coffee file in the modules directory. Each channel has its own instance of a given module, so that module data can be channel specific, e.g., each channel can have its own list of chat filters, etc. To accomodate this, a channel object requests that a desired module be instantiated by `module`. `module` registers a file listener to listen for any new modules being installed, and will also manually attempt to load a module with a given name from the filesystem. Once the module instance is created, it is tied to that channel.

Although `module` facilitates the creation of module instances, it does not actually define any modules. The only requirement imposed by `module` is that the loaded module has a `name`, `description`, and `version` attribute, and that it contains a `New` function that returns an instance appropriate for the channel it is being created for. However, there are other requirements of a module. Specifically, the module class must have both a `load` and `unload` function, which  are called, respectively, when the module is first loaded or reloaded, and when the module is being removed. It must also contain a `handle` function, which is called by its associated channel whenever the channel receives data. The handle function is passed the user who said the message received, the contents of the message, and the instance of the bot server.

In summary, the skeleton of a module should be as follows:

	class MyModule
		constructor: (...) ->
			# This will typically store the channel instance,
			# but this is not a requirement
		load: ->
			...
		unload: ->
			...
		handle: (user, message, bot) ->
			...
	exports.New = (channel) ->
		new MyModule ...

