DROP TABLE IF EXISTS `badwords`;

CREATE TABLE `badwords` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `word` varchar(20) NOT NULL DEFAULT '',
  PRIMARY KEY (`chanid`,`word`)
);


DROP TABLE IF EXISTS `blacklist`;

CREATE TABLE `blacklist` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `url` varchar(100) NOT NULL DEFAULT '',
  PRIMARY KEY (`chanid`,`url`)
);


DROP TABLE IF EXISTS `channel`;

CREATE TABLE `channel` (
  `chanid` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(30) DEFAULT NULL,
  `description` varchar(100) DEFAULT NULL,
  `root` varchar(100) NOT NULL,
  PRIMARY KEY (`chanid`),
  UNIQUE KEY `name` (`name`)
);


DROP TABLE IF EXISTS `commands`;

CREATE TABLE `commands` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `cmdtrigger` varchar(20) NOT NULL,
  `message` varchar(250) NOT NULL,
  PRIMARY KEY (`chanid`,`cmdtrigger`)
);


DROP TABLE IF EXISTS `counter`;

CREATE TABLE `counter` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `name` varchar(20) NOT NULL,
  `value` int(11) DEFAULT '0',
  PRIMARY KEY (`chanid`,`name`)
);


DROP TABLE IF EXISTS `emotes`;

CREATE TABLE `emotes` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `emote` varchar(15) NOT NULL DEFAULT '',
  PRIMARY KEY (`chanid`,`emote`)
);


DROP TABLE IF EXISTS `filterstate`;

CREATE TABLE `filterstate` (
  `chanid` int(11) NOT NULL,
  `url` tinyint(1) DEFAULT '0',
  `caps` tinyint(1) DEFAULT '0',
  `emotes` tinyint(1) DEFAULT '0',
  `words` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`chanid`)
);


DROP TABLE IF EXISTS `jm`;

CREATE TABLE `jm` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `run` int(11) NOT NULL DEFAULT '0',
  `time` int(11) DEFAULT NULL,
  `block` varchar(15) NOT NULL DEFAULT '',
  PRIMARY KEY (`chanid`,`run`,`block`)
);


DROP TABLE IF EXISTS `moderator`;

CREATE TABLE `moderator` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `userid` int(11) NOT NULL DEFAULT '0',
  `level` int(11) DEFAULT NULL,
  PRIMARY KEY (`chanid`,`userid`)
);


DROP TABLE IF EXISTS `module`;

CREATE TABLE `module` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `module` varchar(30) NOT NULL,
  `state` tinyint(1) DEFAULT 0, 
  PRIMARY KEY (`chanid`,`module`)
);


DROP TABLE IF EXISTS `news`;

CREATE TABLE `news` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `newsid` int(11) NOT NULL DEFAULT '0',
  `message` varchar(250) NOT NULL,
  PRIMARY KEY (`chanid`,`newsid`)
);


DROP TABLE IF EXISTS `newsconf`;

CREATE TABLE `newsconf` (
  `chanid` int(11) NOT NULL,
  `state` tinyint(1) DEFAULT '0',
  `seconds` int(11) DEFAULT '150',
  `messages` int(11) DEFAULT '15',
  PRIMARY KEY (`chanid`)
);


DROP TABLE IF EXISTS `users`;

CREATE TABLE `users` (
  `userid` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(30) DEFAULT NULL,
  `password` varchar(50) DEFAULT NULL,
  `global` tinyint(1) DEFAULT '0',
  `email` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`userid`),
  UNIQUE KEY `username` (`username`)
);


DROP TABLE IF EXISTS `vm`;

CREATE TABLE `vm` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `run` int(11) NOT NULL DEFAULT '0',
  `time` int(11) DEFAULT NULL,
  `block` varchar(15) NOT NULL DEFAULT '',
  PRIMARY KEY (`chanid`,`run`,`block`)
);


DROP TABLE IF EXISTS `whitelist`;

CREATE TABLE `whitelist` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `url` varchar(100) NOT NULL DEFAULT '',
  PRIMARY KEY (`chanid`,`url`)
);

DROP TABLE IF EXISTS `poll`;

CREATE TABLE `poll` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `name` varchar(20) NOT NULL,
  `options` varchar(300) NOT NULL,
  PRIMARY KEY (`chanid`, `name`)
);
