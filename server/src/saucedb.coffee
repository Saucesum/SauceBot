# SauceBot Database Module

Sauce = require './sauce'
io    = require './ioutil'

mysql = require 'mysql'

client = mysql.createClient
        user     : Sauce.DB.username
        password : sauce.DB.password

client.useDatabase Sauce.DB.database

exports.getChanData = (channel, table, callback) ->
    client.query(
        "SELECT * FROM #{table} WHERE chanid = ?",
        [channel], (err, results) ->
            throw err if err
            callback results
    )


exports.getChanDataEach = (channel, table, callback, lastcb) ->
    exports.getChanData channel, table, (results) ->
        callback result for result in results
        lastcb()


exports.getData = (table, callback) ->
    client.query(
        "SELECT * FROM #{table}",
        (err, results) ->
            throw err if err
            callback results
    )


exports.getDataEach = (table, callback, lastcb) ->
    exports.getData table, (results) ->
        callback result for result in results
        lastcb()


exports.clearChanData = (channel, table, cb) ->
    client.query "DELETE FROM #{table} WHERE chanid = ?", [channel], cb


exports.removeChanData = (channel, table, field, value, cb) ->
    client.query "DELETE FROM #{table} WHERE #{field} = ? AND chanid = ?", [value, channel], cb


getWildcards = (num) ->
    ('?' for [0..num]).join ', '


exports.addChanData = (channel, table, fields, datalist) ->
    wc = getWildcards fields.length

    query = "REPLACE INTO #{table} (#{fields.join ', '}) VALUES (#{wc})"

    client.query query, data for data in datalist 


exports.setChanData = (channel, table, fields, data) ->
    exports.clearChanData channel, table, ->
        exports.addChanData channel, table, fields, data

exports.loadData = (channel, table, fields, callback) ->
    isObj = typeof fields is 'object'
    key = key.field
    val = if isObj then fields.value else fields
    
    data = if isObj then {} else []

    client.query(
        "SELECT * FROM #{table} WHERE chanid = ?",
        [channel], (err, results) ->
            throw err if err
            if (isObj)
                data[result[key]] = result[val] for result in results
            else
                data.push result[val]           for result in results
             
            callback data
    )

