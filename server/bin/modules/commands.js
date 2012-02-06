(function() {
  var Commands, Sauce, db, io;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  Sauce = require('../sauce');
  db = require('../saucedb');
  io = require('../ioutil');
  exports.name = 'Commands';
  exports.version = '1.1';
  exports.description = 'Custom commands handler';
  io.module('[Commands] Init');
  Commands = (function() {
    function Commands(channel) {
      this.channel = channel;
      this.commands = {};
    }
    Commands.prototype.load = function(chan) {
      if (chan != null) {
        this.channel = chan;
      }
      return db.loadData(this.channel.id, 'commands', {
        key: 'cmdtrigger',
        value: 'message'
      }, __bind(function(commands) {
        this.commands = commands;
        return io.module("[Commands] Loaded commands for " + this.channel.id + ": " + this.channel.name);
      }, this));
    };
    Commands.prototype.unsetCommand = function(command) {
      delete this.commands[command];
      return db.removeChanData(this.channel.id, 'commands', 'cmdtrigger', command);
    };
    Commands.prototype.setCommand = function(command, message) {
      this.commands[command] = message;
      return db.addChanData(this.channel.id, 'commands', ['cmdtrigger', 'message'], [[command, message]]);
    };
    Commands.prototype.handle = function(user, command, args, sendMessage) {
      var cmd, msg, op, res;
      op = user.op;
      res = void 0;
      if ((op != null) && (command === 'set' || command === 'unset')) {
        if (args.length === 1) {
          cmd = args[0];
          this.unsetCommand(cmd);
          res = "Command unset: " + cmd;
        } else if (args.length > 1) {
          cmd = args.splice(0, 1);
          msg = args.join(' ');
          this.setCommand(cmd, msg);
          res = "Command set: " + cmd;
        }
      } else {
        res = this.commands[command];
      }
      if (res != null) {
        return sendMessage(res);
      }
    };
    return Commands;
  })();
  exports.New = function(channel) {
    return new Commands(channel);
  };
}).call(this);
