/* SauceBot user data */

var Sauce = require('./sauce');

var db    = require('./saucedb');
var io    = require('./ioutil');


/* User list - indexed by username */
var users = {};

/* Name list for quick userid -> username lookup */
var names = {};

/* Constructs a new User object from a database result */
function User(data) {
	this.id     = data.userid;
	this.name   = data.username;
	this.global = data.global;
	
	this.mod = {};
}

/* Returns whether the user is a global administrator */
User.prototype.isGlobal = function() {
	return this.global == 1;
}

/* Sets the user's moderator level in the specified channel */
User.prototype.setMod = function(chan, level) {
	this.mod[chan] = level;
}

/* Returns whether the user is a mod of the specified level */
User.prototype.isMod = function(chan, modLevel) {
	if (!modLevel) {
		modLevel = Sauce.Level.Mod;
	}
	return this.isGlobal() || 
	       this.mod[chan] >= modLevel;
}

/* Returns a user by their lowercase username */
function getByName(name) {
	return users[name];
}

/* Returns a user by their UserID */
function getById(id) {
	return getByName(names[id]);
}

/* Updates the user list */
function loadUsers(cb) {
	// Clear the user list
	users = {};
	names = {};
	
	db.getDataEach('users', function(u) {
		var id = u.userid;
		var name = u.username.toLowerCase();
		var global = u.global;
		
		var user = new User(u);
		users[name] = user;
		names[id  ] = name;
		
	}, function() {
		updateModLevels(cb);
	});
}

/* Updates every user's mod levels */
function updateModLevels(cb) {
	db.getDataEach('moderator', function(m) {
		var user = users[names[m.userid]];
		user.setMod(m.chanid, m.level);
		
	}, function() {
		if (cb) {
			cb(users);
		}
	});
}

// Variables
exports.users = users;

// Classes
exports.User = User;

// Methods
exports.load = loadUsers;
exports.getByName = getByName;
exports.getById = getById;
