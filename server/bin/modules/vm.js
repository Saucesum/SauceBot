(function() {
  var Sauce, VM, block, blocks, blocksLC, db, io;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  Sauce = require('../sauce');
  db = require('../saucedb');
  io = require('../ioutil');
  exports.name = 'VM';
  exports.version = '1.1';
  exports.description = 'Victory Monument live tracker';
  blocks = ['White', 'Orange', 'Magenta', 'Light_blue', 'Yellow', 'Lime', 'Pink', 'Gray', 'Light_gray', 'Cyan', 'Purple', 'Blue', 'Brown', 'Green', 'Red', 'Black', 'Iron', 'Gold', 'Diamond'];
  blocksLC = (function() {
    var _i, _len, _results;
    _results = [];
    for (_i = 0, _len = blocks.length; _i < _len; _i++) {
      block = blocks[_i];
      _results.push(block.toLowerCase());
    }
    return _results;
  })();
  io.module('[VM] Init');
  VM = (function() {
    function VM(channel) {
      this.channel = channel;
      this.obtained = {};
    }
    VM.prototype.save = function() {
      var block;
      io.module("[VM] Saving " + this.channel.name + " ...");
      return db.setChanData(this.channel.id, 'vm', ['chanid', 'block'], (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = blocksLC.length; _i < _len; _i++) {
          block = blocksLC[_i];
          if (this.obtained[block] != null) {
            _results.push([this.channel.id, block]);
          }
        }
        return _results;
      }).call(this));
    };
    VM.prototype.load = function(chan) {
      if (chan != null) {
        this.channel = chan;
      }
      io.module("[VM] Loading " + this.channel.id + ": " + this.channel.name);
      return db.loadData(this.channel.id, 'vm', 'block', __bind(function(blocks) {
        var block, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = blocks.length; _i < _len; _i++) {
          block = blocks[_i];
          _results.push(this.obtained[block] = true);
        }
        return _results;
      }, this));
    };
    VM.prototype.clearVM = function() {
      this.obtained = {};
      this.save();
      return 'Cleared';
    };
    VM.prototype.getVM = function() {
      var block, obtained;
      obtained = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = blocks.length; _i < _len; _i++) {
          block = blocks[_i];
          if (this.obtained[block.toLowerCase()] != null) {
            _results.push(block);
          }
        }
        return _results;
      }).call(this);
      return "Blocks: " + (obtained.join(', '));
    };
    VM.prototype.setVM = function(args) {
      var idx;
      if (args == null) {
        return;
      }
      block = args[0].toLowerCase();
      if ((idx = blocksLC.indexOf(block)) === -1) {
        return "Unknown block '" + block + "'. Usage: !vm (white|light_gray|light_blue|diamond|...)";
      }
      this.obtained[block] = true;
      this.save();
      return "Added " + blocks[idx] + ".";
    };
    VM.prototype.handle = function(user, command, args, sendMessage) {
      var name, op, res;
      name = user.name, op = user.op;
      if (!((op != null) && command === 'vm')) {
        return;
      }
      if (!(args != null) || args[0] === '') {
        res = this.getVM();
      } else if (args[0] === 'clear') {
        res = this.clearVM();
      } else {
        res = this.setVM(args);
      }
      if (res != null) {
        return sendMessage("[VM] " + res);
      }
    };
    return VM;
  })();
  exports.New = function(channel) {
    return new VM(channel);
  };
}).call(this);
