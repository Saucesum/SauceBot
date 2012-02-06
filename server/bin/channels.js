(function() {
  var Channel, Sauce, channels, db, io, mod, moduleNames, names, users;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  Sauce = require('./sauce');
  db = require('./saucedb');
  users = require('./users');
  io = require('./ioutil');
  mod = require('./module');
  moduleNames = Object.keys(mod.MODULES);
  channels = {};
  names = {};
  Channel = (function() {
    function Channel(data) {
      this.id = data.chanid;
      this.name = data.name;
      this.desc = data.description;
      this.modules = [];
      this.loadChannelModules();
    }
    Channel.prototype.addModule = function(moduleName) {
      var module;
      try {
        module = mod.instance(moduleName);
        module.load(this);
        return this.modules.push(module);
      } catch (error) {
        return io.error("" + error);
      }
    };
    Channel.prototype.loadChannelModules = function() {
      return db.getChanDataEach(this.id, 'module', __bind(function(result) {
        this.addModule(result.module);
        return io.debug("Channel " + this.name + " uses module " + result.module);
      }, this), __bind(function() {
        return io.debug("Done loading modules for " + this.name);
      }, this));
    };
    Channel.prototype.getUser = function(username, op) {
      var chan, user;
      if (!op) {
        op = null;
      }
      chan = this.name;
      user = users.getByName(username);
      if ((user != null)) {
        return {
          name: user.name,
          op: op || user.isMod(chan)
        };
      }
      return {
        name: username,
        op: op
      };
    };
    Channel.prototype.handle = function(data, sendMessage, finished) {
      var command, module, user, _i, _len, _ref;
      user = this.getUser(data.username, data.op);
      command = data.commands;
      arguments = data.arguments;
      _ref = this.modules;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        module = _ref[_i];
        module.handle(user, command, arguments, sendMessage);
      }
      if (finished != null) {
        return finished();
      }
    };
    return Channel;
  })();
  exports.handle = function(channel, data, sendMessage, finished) {
    return channels[channel].handle(data, sendMessage, finished);
  };
  exports.load = function(finished) {
    channels = {};
    names = {};
    return db.getDataEach('channel', function(chan) {
      var channel, desc, id, name;
      id = chan.chanid;
      name = chan.name.toLowerCase();
      desc = chan.description;
      channel = new Channel(chan);
      channels[name] = channel;
      return names[id] = name;
    }, function() {
      if (finished != null) {
        return finished(channels);
      }
    });
  };
}).call(this);
