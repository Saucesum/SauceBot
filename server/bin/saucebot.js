/*
 * Node.js implementation of SauceBot Command Server
 * 
 * @author Ravn T-M
 * 
 */

var Sauce = require('./sauce');

var db    = require('./saucedb');
var users = require('./users');
var chans = require('./channels');

var io    = require('./ioutil');

var net   = require('net');
var url   = require('url' );
var color = require('colors');

io.module("Loading users...");
users.load(function(userlist) {
	io.module("Loaded " + Object.keys(userlist).length + " users.");
});

io.module("Loading channels...");
chans.load(function(chanlist) {
	io.module("Loaded " + Object.keys(chanlist).length + " channels.");
});

function sendError(serv, msg) {
	var json = JSON.stringify({
		error: 1,
		msg: msg
	});
	io.say('>> '.red + msg);
	serv.write(json + '\n');
}

function say(serv, chan, msg) {
	send(serv, 'say', chan, msg);
}

function send(serv, act, chan, msg) {
	var json = JSON.stringify({
		act: act,
		chan: chan,
		msg: msg
	});
	io.say('>> '.magenta + act + ' ' + chan + ': ' + msg);
	serv.write(json + '\n');
}

var server = net.createServer(function handler(socket) {
	socket.setEncoding('utf8');
	var ip = socket.remoteAddress;
	
	io.say('Client connected: '.magenta + ip);

	socket.on('data', function onData(rawdatas) {
		if (rawdatas.length == 0) {
			return;
		}
		
		rawdata = rawdatas.split('\n');
		for (var i = 0; i < rawdata.length; i++) {
			if (!rawdata[i]) {
				continue;
			}
			try {
				var json = JSON.parse(rawdata[i]);
				var chan = json.chan;
				var data = {
						username : json.user,
						commands : json.cmd,
						arguments: json.args.split(' ')
				};
				
				data.op = json.op? 1 : null;
				
				chans.handle(chan, data, function sendData(data) {
					say(socket, chan, io.noise() + ' ' + data);
				}, function finished() {
				});
				
			} catch (err) {
				sendError(socket, 'invalid syntax in message "' + rawdata[i] + '": '  + err);
			}
		}
	});

	socket.on('end', function onEnd() {
		io.say('Client disconnected: '.magenta + ip);
	});
});

server.listen(8455);
io.say('Server started at port 8455'.cyan);

//var server = http.createServer(function webHandler(req, res) {
//	var query = url.parse(req.url, true).query;
//	if (!query['chan']) {
//		return;
//	}
//	
//	var chan = query.chan;
//
//	var data = {
//			username : query.name,
//			commands : query.cmd,
//			arguments: query.args.split(' ')
//	}
//	
//	res.writeHead(200, {
//		'Content-Type': 'application/json',
//		'Access-Control-Allow-Origin': '*'
//	});
//	
//	var results = [];
//	
//	res.write('[');
//	
//	chans.handle(chan, data, function sendData(pre, data) {
//		var result = {
//			chan: chan,
//			act: 'say',
//			msg: pre + ' ' + data
//		};
//		results.push(JSON.stringify(result));
//		
//	}, function finished() {
//		res.write(results.join(', '));
//		res.write(']');
//		res.end();
//	});
//	
//	
//});
//
//server.listen(8080);
//io.debug("Server started.");
