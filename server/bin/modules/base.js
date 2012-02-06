(function() {
  var Base, Sauce, db, io;
  Sauce = require('../sauce');
  db = require('../saucedb');
  io = require('../ioutil');
  exports.name = 'Base';
  exports.version = '1.1';
  exports.description = 'Global base commands such as !time and !saucebot';
  io.module('[Base] Init');
  Base = (function() {
    function Base(channel) {
      this.channel = channel;
      this.handlers = {
        saucebot: function() {
          return '[SauceBot] SauceBot version 3.1 - Node.js';
        },
        test: function(user) {
          if (user.op != null) {
            return 'Test command!';
          }
        },
        time: function() {
          var date;
          date = new Date;
          return "[Time] " + (date.getHours()) + ":" + (date.getMinutes());
        }
      };
    }
    Base.prototype.load = function(chan) {
      if (chan != null) {
        return this.channel = chan;
      }
    };
    Base.prototype.handle = function(user, command, args, sendMessage) {
      var handler, result;
      handler = this.handlers[command];
      if ((handler != null)) {
        result = handler(user, args);
        if (result != null) {
          return sendMessage(result);
        }
      }
    };
    return Base;
  })();
  exports.New = function(channel) {
    return new Base(channel);
  };
}).call(this);
