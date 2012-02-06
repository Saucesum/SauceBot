# SauceBot Database Module

Sauce = require './sauce'
io    = require './ioutil'

mysql = require 'mysql'

client = mysql.createClient
        user     : Sauce.DB.username
        password : Sauce.DB.password

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
        lastcb() if lastcb


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
        lastcb() if lastcb


exports.clearChanData = (channel, table, cb) ->
    client.query "DELETE FROM #{table} WHERE chanid = ?", [channel], cb


exports.removeChanData = (channel, table, field, value, cb) ->
    client.query "DELETE FROM #{table} WHERE #{field} = ? AND chanid = ?", [value, channel], cb


getWildcards = (num) ->
    ('?' for [1..num]).join ', '


exports.addChanData = (channel, table, fields, datalist) ->
    wc = getWildcards (fields.length + 1)

    query = "REPLACE INTO #{table} (chanid, #{fields.join ', '}) VALUES (#{wc})"
    
    client.query query, [channel].concat data for data in datalist 


exports.setChanData = (channel, table, fields, data) ->
    exports.clearChanData channel, table, ->
        exports.addChanData channel, table, fields, data

exports.loadData = (channel, table, fields, callback) ->
    isObj = typeof fields is 'object'
    key = if isObj then fields.key else null
    val = if isObj then fields.value else fields
    
    data = if key? then {} else []

    client.query(
        "SELECT * FROM #{table} WHERE chanid = ?",
        [channel], (err, results) =>
            throw err if err
            
            for result in results
                if (key?)
                    data[result[key]] = result[val]
                else
                    data.push result[val]
             
            callback data
    )

