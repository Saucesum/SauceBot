# SauceBot Database Module

Sauce = require './sauce'
io    = require './ioutil'

mysql = require 'mysql'

timeOutLimit = 30 * 60 * 1000
lastConnect = 0

client = null

connect = ->
    io.debug "MySQL - Connecting"
    client?.destroy()
    
    client = mysql.createClient
            user     : Sauce.DB.username
            password : Sauce.DB.password
    
    client.useDatabase Sauce.DB.database


timedOut = ->
    previous    = lastConnect
    lastConnect = Date.now()
    
    lastConnect - previous > timeOutLimit


query = (args...) ->
    connect() if timedOut()
    client.query args...


exports.getChanData = (channel, table, callback) ->
    query(
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
    query(
        "SELECT * FROM #{table}",
        (err, results) ->
            throw err if err # TODO
            callback results
    )


exports.getDataEach = (table, callback, lastcb) ->
    exports.getData table, (results) ->
        callback result for result in results
        lastcb() if lastcb


exports.clearChanData = (channel, table, cb) ->
    query "DELETE FROM #{table} WHERE chanid = ?", [channel], cb


exports.clearTable = (table) ->
    query "DELETE FROM #{table}"


exports.removeChanData = (channel, table, field, value, cb) ->
    query "DELETE FROM #{table} WHERE #{field} = ? AND chanid = ?", [value, channel], cb


getWildcards = (num) ->
    ('?' for [1..num]).join ', '


exports.addChanData = (channel, table, fields, datalist) ->
    exports.addData(table, ['chanid'].concat(fields), [channel].concat(data) for data in datalist)


exports.addData = (table, fields, datalist) ->
    wc = getWildcards fields.length
    queryStr = "REPLACE INTO #{table} (#{fields.join ', '}) VALUES (#{wc})"
    
    query queryStr, data for data in datalist


exports.setChanData = (channel, table, fields, data) ->
    exports.clearChanData channel, table, ->
        exports.addChanData channel, table, fields, data


exports.loadData = (channel, table, fields, callback) ->
    isObj = typeof fields is 'object'
    key = if isObj then fields.key else null
    val = if isObj then fields.value else fields
    
    data = if key? then {} else []

    query(
        "SELECT * FROM #{table} WHERE chanid = ?",
        [channel], (err, results) =>
            throw err if err # TODO
            
            for result in results
                if (key?)
                    data[result[key]] = result[val]
                else
                    data.push result[val]
             
            callback data
    )

