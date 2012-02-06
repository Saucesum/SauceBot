(function() {
  var Filters, Sauce, db, filterNames, io, tableFields, tableNames;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  };
  Sauce = require('../sauce');
  db = require('../saucedb');
  io = require('../ioutil');
  exports.name = 'Filters';
  exports.version = '1.1';
  exports.description = 'Filters URLs, caps-lock, words and emotes';
  filterNames = ['url', 'caps', 'words', 'emotes'];
  tableNames = ['whitelist', 'blacklist', 'badwords', 'emotes'];
  tableFields = {
    whitelist: 'url',
    blacklist: 'url',
    badwords: 'word',
    emotes: 'emote'
  };
  io.module('[Filters] Init');
  Filters = (function() {
    function Filters(channel) {
      this.channel = channel;
      this.state = {
        url: 0,
        caps: 0,
        words: 0,
        emotes: 0
      };
      this.lists = {
        whitelist: [],
        blacklist: [],
        badwords: [],
        emotes: []
      };
    }
    Filters.prototype.loadTable = function(table) {
      return db.loadData(this.channel.id, table, tableFields[table], __bind(function(data) {
        this.lists[table] = data;
        return io.module("Updated " + table + " for " + this.channel.id + ":" + this.channel.name);
      }, this));
    };
    Filters.prototype.saveTable = function(table) {
      var field, value;
      field = tableFields[table];
      io.module("Saving filter data for " + table + "...");
      return db.setChanData(this.channel.id, table, ['chanid', field], (function() {
        var _i, _len, _ref, _results;
        _ref = this.lists[table];
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          value = _ref[_i];
          _results.push([this.channel.id, value]);
        }
        return _results;
      }).call(this));
    };
    Filters.prototype.loadStates = function() {
      return db.getChanDataEach(this.channel.id, 'filterstate', __bind(function(data) {
        var caps, emotes, url, words;
        url = data.url, caps = data.caps, emotes = data.emotes, words = data.words;
        this.state.url = url;
        this.state.caps = caps;
        this.state.words = words;
        return this.state.emotes = emotes;
      }, this));
    };
    Filters.prototype.saveStates = function() {
      var caps, emotes, url, words, _ref;
      _ref = this.state, url = _ref.url, caps = _ref.caps, emotes = _ref.emotes, words = _ref.words;
      io.module('Saving filter states...');
      return db.setChanData(this.channel.id, 'filterstate', ['chanid', 'url', 'caps', 'emotes', 'words'], [[this.channel.id, url, caps, emotes, words]]);
    };
    Filters.prototype.load = function(chan) {
      var table, _i, _len;
      if (chan != null) {
        this.channel = chan;
      }
      for (_i = 0, _len = tableNames.length; _i < _len; _i++) {
        table = tableNames[_i];
        this.loadTable(table);
      }
      return this.loadStates();
    };
    Filters.prototype.checkFilters = function(name, msglist) {};
    Filters.prototype.handleFilterStateCommand = function(filter, state) {
      if ((state != null)) {
        if (state === 'on') {
          this.state[filter] = 1;
          this.saveStates();
          return "" + filter + " is now enabled.";
        } else if (state === 'off') {
          this.state[filter] = 0;
          this.saveStates();
          return "" + filter + " is now disabled.";
        } else {
          return "Invalid state: '" + state + "'. usage: !filter " + filter + " <on/off>";
        }
      } else {
        if (this.state[filter] === 1) {
          return "" + filter + "-filter enabled.";
        } else {
          return "" + filter + "-filter disabled.";
        }
      }
    };
    Filters.prototype.handleFilterCommand = function(command, filter, arg, value) {
      var idx, list, res;
      list = this.lists[command];
      if (arg === 'add') {
        list.push(value);
        res = "Added '" + value + "'.";
      } else if (arg === 'remove') {
        idx = list.indexOf(value);
        if (idx === -1) {
          res = "No such value '" + value;
        } else {
          list.splice(idx, 1);
          res = "Removed '" + value + "'.";
        }
      } else if (arg === 'clear') {
        this.lists[command] = [];
        res = "Cleared.";
      } else {
        return;
      }
      this.saveTable(command);
      return "[" + command + "] " + res;
    };
    Filters.prototype.handleCommand = function(command, args) {
      var arg, field, filter, res, state, value;
      if (command === 'filter') {
        filter = args[0];
        state = args[1];
        if (filterNames.indexOf(filter) !== -1) {
          res = this.handleFilterStateCommand(filter, state);
        }
        return "[Filter] " + res;
      } else if ((__indexOf.call(tableNames, command) >= 0)) {
        field = tableFields[command];
        arg = args[0];
        value = args[1];
        return res = this.handleFilterCommand(command, filter, arg, value);
      }
    };
    Filters.prototype.handle = function(user, command, args, sendMessage) {
      var name, op, res;
      name = user.name, op = user.op;
      if ((op != null)) {
        if (!((command != null) && command !== '')) {
          return;
        }
        res = this.handleCommand(command, args);
      } else {
        res = this.checkFilters(name, [command].concat(args));
      }
      if (res != null) {
        return sendMessage(res);
      }
    };
    return Filters;
  })();
  exports.New = function(channel) {
    return new Filters(channel);
  };
}).call(this);
