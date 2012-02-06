(function() {
  var News, Sauce, db, io;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  Sauce = require('../sauce');
  db = require('../saucedb');
  io = require('../ioutil');
  exports.name = 'News';
  exports.version = '1.1';
  exports.description = 'Automatic news broadcasting';
  io.module('[News] Init');
  News = (function() {
    function News(channel) {
      this.channel = channel;
      this.news = [];
      this.state = 0;
      this.seconds = 150;
      this.messages = 15;
      this.index = 0;
      this.lastTime = io.now();
      this.messageCount = 0;
    }
    News.prototype.load = function(chan) {
      if (chan != null) {
        this.channel = chan;
      }
      db.loadData(this.channel.id, 'news', 'message', __bind(function(data) {
        this.news = data;
        return io.module("Updated news for " + this.channel.id + ": " + this.channel.name);
      }, this));
      return db.getChanDataEach(this.channel.id, 'newsconf', __bind(function(conf) {
        this.state = conf.state;
        this.seconds = conf.seconds;
        return this.messages = conf.messages;
      }, this));
    };
    News.prototype.save = function() {
      var message, newsid;
      newsid = 0;
      db.setChanData(this.channel.id, 'news', ['chanid', 'newsid', 'message'], (function() {
        var _i, _len, _ref, _results;
        _ref = this.news;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          message = _ref[_i];
          _results.push([this.channel.id, newsid++, message]);
        }
        return _results;
      }).call(this));
      db.setChanData(this.channel.id, 'newsconf', ['chanid', 'state', 'seconds', 'messages'], [[this.channel.id, this.state, this.seconds, this.messages]]);
      return io.module("News saved");
    };
    News.prototype.getNext = function() {
      if (this.news.length === 0) {
        return;
      }
      if (this.index >= this.news.length) {
        this.index = 0;
      }
      return "[News] " + this.news[this.index++];
    };
    News.prototype.tickNews = function() {
      var now;
      now = io.now();
      this.messageCount++;
      if (!((this.state === 1) && (now > (this.lastTime + this.seconds)) && (this.messageCount >= this.messages))) {
        return;
      }
      this.lastTime = now;
      this.messageCount = 0;
      return this.getNext();
    };
    News.prototype.handle = function(user, command, args, sendMessage) {
      var arg, line, msg, name, news, newsSent, op, res, updated;
      name = user.name, op = user.op;
      newsSent = null;
      if (((news = this.tickNews()) != null)) {
        sendMessage((newsSent = news));
      }
      if (!((op != null) && command === 'news')) {
        return;
      }
      arg = args[0];
      res = null;
      if (!(arg != null) || arg === '') {
        if (!(newsSent != null)) {
          if (((msg = this.getNext()) != null)) {
            res = msg;
          } else {
            res = '<News> No auto-news found. Add with !news add <message>';
          }
        }
      } else {
        updated = true;
        res = (function() {
          switch (arg) {
            case 'on':
              this.state = 1;
              return '<News> Auto-news is now enabled.';
            case 'off':
              this.state = 0;
              return '<News> Auto-news is now disabled.';
            case 'seconds':
              if (args[1] != null) {
                this.seconds = parseInt(args[1], 10);
              }
              return "<News> Auto-news minimum delay set to " + this.seconds + " seconds.";
              break;
            case 'messages':
              if (args[1] != null) {
                this.messages = parseInt(args[1], 10);
              }
              return "<News> Auto-news minimum messages set to " + this.messages + ".";
              break;
            case 'add':
              line = args.slice(1).join(' ');
              this.news.push(line);
              return '<News> Auto-news added.';
            case 'clear':
              this.news = [];
              return '<News> Auto-news cleared.';
            default:
              return updated = null;
          }
        }).call(this);
        if (updated != null) {
          this.save();
        }
      }
      if (res != null) {
        return sendMessage(res);
      }
    };
    return News;
  })();
  exports.New = function(channel) {
    return new News(channel);
  };
}).call(this);
