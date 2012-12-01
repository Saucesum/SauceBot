-- MySQL dump 10.13  Distrib 5.1.66, for debian-linux-gnu (i686)
--
-- Host: localhost    Database: saucebot
-- ------------------------------------------------------
-- Server version	5.1.66-0ubuntu0.11.10.2

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `applications`
--

DROP TABLE IF EXISTS `applications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `applications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `time` int(20) DEFAULT NULL,
  `userid` int(11) DEFAULT NULL,
  `channel` varchar(50) DEFAULT NULL,
  `why` text,
  `seen` text,
  `feature` text,
  `viewers` text,
  `put` text,
  `status` int(2) DEFAULT '0',
  `handledby` int(11) DEFAULT NULL,
  `reason` text,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `autocommercial`
--

DROP TABLE IF EXISTS `autocommercial`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `autocommercial` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `state` tinyint(1) DEFAULT NULL,
  `delay` int(11) DEFAULT NULL,
  `messages` int(11) DEFAULT NULL,
  PRIMARY KEY (`chanid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `badwords`
--

DROP TABLE IF EXISTS `badwords`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `badwords` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `word` varchar(25) NOT NULL DEFAULT '',
  PRIMARY KEY (`chanid`,`word`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `blacklist`
--

DROP TABLE IF EXISTS `blacklist`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `blacklist` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `url` varchar(100) NOT NULL DEFAULT '',
  PRIMARY KEY (`chanid`,`url`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `channel`
--

DROP TABLE IF EXISTS `channel`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `channel` (
  `chanid` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(30) DEFAULT NULL,
  `status` int(3) DEFAULT '0',
  `bot` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`chanid`),
  UNIQUE KEY `name` (`name`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `channelconfig`
--

DROP TABLE IF EXISTS `channelconfig`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `channelconfig` (
  `chanid` int(11) NOT NULL,
  `modonly` tinyint(1) DEFAULT '0',
  `quiet` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`chanid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `commands`
--

DROP TABLE IF EXISTS `commands`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `commands` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `cmdtrigger` varchar(20) NOT NULL,
  `message` varchar(350) DEFAULT NULL,
  `level` int(11) DEFAULT '0',
  PRIMARY KEY (`chanid`,`cmdtrigger`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `countdown`
--

DROP TABLE IF EXISTS `countdown`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `countdown` (
  `chanid` int(11) NOT NULL,
  `name` varchar(15) NOT NULL,
  `time` mediumtext,
  PRIMARY KEY (`chanid`),
  UNIQUE KEY `name` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `countdowns`
--

DROP TABLE IF EXISTS `countdowns`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `countdowns` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `name` varchar(20) NOT NULL DEFAULT '',
  `time` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`chanid`,`name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `counter`
--

DROP TABLE IF EXISTS `counter`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `counter` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `name` varchar(20) NOT NULL,
  `value` int(11) DEFAULT '0',
  PRIMARY KEY (`chanid`,`name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `emotes`
--

DROP TABLE IF EXISTS `emotes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `emotes` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `emote` varchar(25) NOT NULL DEFAULT '',
  PRIMARY KEY (`chanid`,`emote`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `filterstate`
--

DROP TABLE IF EXISTS `filterstate`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `filterstate` (
  `chanid` int(11) NOT NULL,
  `url` tinyint(1) DEFAULT '0',
  `caps` tinyint(1) DEFAULT '0',
  `emotes` tinyint(1) DEFAULT '0',
  `words` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`chanid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `helprequests`
--

DROP TABLE IF EXISTS `helprequests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `helprequests` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `time` int(11) NOT NULL DEFAULT '0',
  `user` varchar(25) DEFAULT 'Anonymous',
  `reason` varchar(300) DEFAULT '',
  `handled` int(11) DEFAULT '0',
  PRIMARY KEY (`chanid`,`time`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `jm`
--

DROP TABLE IF EXISTS `jm`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `jm` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `run` int(11) NOT NULL DEFAULT '0',
  `time` int(11) DEFAULT NULL,
  `block` varchar(15) NOT NULL DEFAULT '',
  PRIMARY KEY (`chanid`,`run`,`block`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `moderator`
--

DROP TABLE IF EXISTS `moderator`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `moderator` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `userid` int(11) NOT NULL DEFAULT '0',
  `level` int(11) DEFAULT NULL,
  PRIMARY KEY (`chanid`,`userid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `module`
--

DROP TABLE IF EXISTS `module`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `module` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `module` varchar(30) NOT NULL,
  `state` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`chanid`,`module`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `moduleinfo`
--

DROP TABLE IF EXISTS `moduleinfo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `moduleinfo` (
  `name` varchar(30) NOT NULL,
  `description` varchar(300) DEFAULT NULL,
  `version` varchar(5) DEFAULT NULL,
  `defaultstate` tinyint(1) DEFAULT '1',
  `locked` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `news`
--

DROP TABLE IF EXISTS `news`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `news` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `newsid` int(11) NOT NULL DEFAULT '0',
  `message` varchar(250) NOT NULL,
  PRIMARY KEY (`chanid`,`newsid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `newsconf`
--

DROP TABLE IF EXISTS `newsconf`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `newsconf` (
  `chanid` int(11) NOT NULL,
  `state` tinyint(1) DEFAULT '0',
  `seconds` int(11) DEFAULT '150',
  `messages` int(11) DEFAULT '15',
  PRIMARY KEY (`chanid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `passwordrequests`
--

DROP TABLE IF EXISTS `passwordrequests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `passwordrequests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(30) NOT NULL,
  `password` varchar(50) NOT NULL,
  `email` varchar(100) DEFAULT NULL,
  `code` varchar(10) DEFAULT NULL,
  `handled` int(11) DEFAULT '0',
  `time` int(20) DEFAULT NULL,
  `ip` varchar(16) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `pokemonconf`
--

DROP TABLE IF EXISTS `pokemonconf`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pokemonconf` (
  `chanid` int(11) NOT NULL,
  `modonly` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`chanid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `poll`
--

DROP TABLE IF EXISTS `poll`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `poll` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `name` varchar(20) NOT NULL,
  `options` varchar(300) NOT NULL,
  PRIMARY KEY (`chanid`,`name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `quotes`
--

DROP TABLE IF EXISTS `quotes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `quotes` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `list` varchar(20) DEFAULT NULL,
  `quote` text,
  PRIMARY KEY (`chanid`,`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `regulars`
--

DROP TABLE IF EXISTS `regulars`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `regulars` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `username` varchar(25) NOT NULL DEFAULT '',
  PRIMARY KEY (`chanid`,`username`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `session`
--

DROP TABLE IF EXISTS `session`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `session` (
  `userid` int(11) NOT NULL DEFAULT '0',
  `time` bigint(20) DEFAULT NULL,
  `ip` varchar(15) DEFAULT NULL,
  `page` varchar(200) DEFAULT 'N/A',
  PRIMARY KEY (`userid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sitenews`
--

DROP TABLE IF EXISTS `sitenews`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sitenews` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `time` int(20) NOT NULL,
  `userid` int(11) NOT NULL,
  `title` varchar(100) NOT NULL,
  `body` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `spam`
--

DROP TABLE IF EXISTS `spam`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `spam` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `list` int(11) DEFAULT NULL,
  `time` int(20) DEFAULT NULL,
  `channel` int(11) DEFAULT '0',
  `user` varchar(30) NOT NULL,
  `handled` int(11) DEFAULT '0',
  `message` text,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `spamlist`
--

DROP TABLE IF EXISTS `spamlist`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `spamlist` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `link` varchar(500) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `statusupdates`
--

DROP TABLE IF EXISTS `statusupdates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `statusupdates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `userid` int(11) DEFAULT NULL,
  `body` varchar(500) DEFAULT NULL,
  `time` int(20) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `strings`
--

DROP TABLE IF EXISTS `strings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `strings` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `key` varchar(50) NOT NULL,
  `value` varchar(100) NOT NULL,
  PRIMARY KEY (`chanid`,`key`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `timers`
--

DROP TABLE IF EXISTS `timers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `timers` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `name` varchar(20) NOT NULL DEFAULT '',
  `time` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`chanid`,`name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `userkeys`
--

DROP TABLE IF EXISTS `userkeys`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `userkeys` (
  `userid` int(11) NOT NULL DEFAULT '0',
  `code` varchar(32) NOT NULL DEFAULT '',
  PRIMARY KEY (`userid`,`code`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `userid` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(30) DEFAULT NULL,
  `password` varchar(50) DEFAULT NULL,
  `global` tinyint(1) DEFAULT '0',
  `email` varchar(100) DEFAULT NULL,
  `verified` int(1) DEFAULT '0',
  PRIMARY KEY (`userid`),
  UNIQUE KEY `username` (`username`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `vm`
--

DROP TABLE IF EXISTS `vm`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `vm` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `run` int(11) NOT NULL DEFAULT '0',
  `time` int(11) DEFAULT NULL,
  `block` varchar(15) NOT NULL DEFAULT '',
  PRIMARY KEY (`chanid`,`run`,`block`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `whitelist`
--

DROP TABLE IF EXISTS `whitelist`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `whitelist` (
  `chanid` int(11) NOT NULL DEFAULT '0',
  `url` varchar(100) NOT NULL DEFAULT '',
  PRIMARY KEY (`chanid`,`url`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2012-12-01  1:32:08
