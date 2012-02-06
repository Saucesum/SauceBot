var color = require('colors');

// Output methods
var DEBUG = true;
var VERBOSE = true;

exports.setDebug   = function(state) { DEBUG   = state; }
exports.setVerbose = function(state) { VERBOSE = state; }

exports.say = function say(word) {
	console.log(word.bold);
}

exports.debug = function debug(word) {
	if (DEBUG) console.log(('[DEBUG] '.bold + word).green);
}

exports.module = function module(word) {
	if (VERBOSE) console.log(('[MODULE] '.bold +word).blue);
}

exports.error = function error(word) {
	console.log(('[ERROR] '.bold + word).red.inverse);
}

// Anti-ban methods
var start = ['(', '<', '{', '['];
var end   = [')', '>', '}', ']'];

var chars = ['!', '>', '<', '?', '#', '%', '&', '+', '-', '_', '\'', '"', '|'];

exports.infix = function infix(word) {
	var idx = randIdx(start);
	return start[idx] + word + end[idx];
}

exports.noise = function noise() {
	var idx = randIdx(chars);
	return chars[idx];
}

function randIdx(arr) {
	return Math.floor(Math.random() * arr.length);
}

// Utility
exports.now = function now() {
	return new Date().getTime() / 1000;
}