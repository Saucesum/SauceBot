/* SauceBot Database Module */

var Sauce = require('./sauce');
var JSON  = require('./json2');
var io    = require('./ioutil');

var mysql = require('mysql');

var client = mysql.createClient({
	user:     Sauce.DB.username,
	password: Sauce.DB.password
});

client.useDatabase(Sauce.DB.database);

function getChanData(channel, table, callback) {
	client.query(
			'SELECT * FROM ' + table + ' WHERE chanid = ?',
			[channel],
			function selectComplete(err, results) {
				if (err) {
					throw err;
				}
				callback(results);
			}
	);
}

function getChanDataEach(channel, table, callback, lastcb) {
	client.query(
			'SELECT * FROM ' + table + ' WHERE chanid = ?',
			[channel],
			function selectComplete(err, results) {
				if (err) {
					throw err;
				}
				for (var i = 0; i < results.length; i++) {
					callback(results[i]);
				}
				if (lastcb) {
					lastcb();
				}
			}
	);
}

function getData(table, callback) {
	client.query(
			'SELECT * FROM ' + table,
			function selectComplete(err, results) {
				if (err) {
					throw err;
				}
				callback(results);
			}
	);
}

function getDataEach(table, callback, lastcb) {
	client.query(
			'SELECT * FROM ' + table,
			function selectComplete(err, results, fields) {
				if (err) {
					throw err;
				}

				for (var i = 0; i < results.length; i++) {
					callback(results[i]);
				}
				if (lastcb) {
					lastcb();
				}
			}
	);
}

function clearChanData(channel, table, cb) {
	client.query('DELETE FROM ' + table + ' WHERE chanid = ?', [channel], cb);
}

function removeChanData(channel, table, field, value, cb) {
	client.query('DELETE FROM ' + table + ' WHERE ' + field + ' = ?', [value], cb);
}

function getWildcards(num) {
	var wc = [];
	for (var i = 0; i < num; i++) {
		wc.push('?');
	}
	return wc.join(', ');
}

function addChanData(channel, table, fields, data) {
	var fieldlen  = fields.length;
	var wildcards = getWildcards(fieldlen);
	
	var query     = 'REPLACE INTO ' + table + ' (' + fields.join(', ') + ') VALUES (' + wildcards + ')';
	
	for (var i = 0; i < data.length; i++) {
		var elem = data[i];
		client.query(query, elem);
	}
}

function setChanData(channel, table, fields, data) {
	clearChanData(channel, table, function doneClearing() {
		addChanData(channel, table, fields, data);
	});
}

function loadData(channel, table, fields, callback) {
	var key;
	var val;
	if (typeof fields == 'object') {
		key = fields.key;
		val = fields.value;
	} else {
		key = null;
		val = fields;
	}
	
	var data = key? {} : [];

	client.query(
			'SELECT * FROM ' + table + ' WHERE chanid = ?',
			[channel],
			function selectComplete(err, results) {
				if (err) {
					throw err;
				}
				for (var i = 0; i < results.length; i++) {
					var result = results[i];
					if (key) {
						data[result[key]] = result[val];
					} else {
						data.push(result[val]);
					}
				}
				callback(data);
			}
	);
}

function saveData(channel, table, fields, data, callback) {
	
}

exports.getChanData = getChanData;
exports.getChanDataEach = getChanDataEach;
exports.getData = getData;
exports.getDataEach = getDataEach;

exports.clearChanData = clearChanData;
exports.removeChanData = removeChanData;

exports.addChanData = addChanData;
exports.setChanData = setChanData;

exports.loadData = loadData;
exports.saveData = saveData;