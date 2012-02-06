(function() {
  var PATH, fs, io, loadModule;
  fs = require('fs');
  io = require('./ioutil');
  PATH = './modules/';
  exports.MODULES = {};
  fs.readdirSync(PATH).forEach(function(file) {
    var match, module;
    if (!(match = /(\w+)\.js$/i.exec(file))) {
      return;
    }
    try {
      module = require(PATH + file);
      io.debug("Loaded module " + module.name + "(" + match[1] + ".js) v" + module.version);
      return exports.MODULES[module.name] = module;
    } catch (error) {
      return io.error("Could not load module " + match[1] + ": " + error);
    }
  });
  loadModule = function(name) {
    var module;
    try {
      module = require("" + PATH + (name.toLowerCase()) + ".js");
      io.debug("Loaded module " + module.name + "(" + (name.toLowerCase()) + ".js) v" + module.version);
      return exports.MODULES[module.name] = module;
    } catch (error) {
      return io.error("Could not load module " + name + ": " + error);
    }
  };
  exports.instance = function(name) {
    var module;
    if (!(exports.MODULES[name] != null)) {
      if (!loadModule(name)) {
        throw new Error("No such module '" + name + "'");
      }
    }
    module = exports.MODULES[name];
    if (!(module.New != null)) {
      throw new Error("Invalid module '" + name);
    }
    return module.New();
  };
}).call(this);
