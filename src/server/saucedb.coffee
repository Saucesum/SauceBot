# SauceBot Database Module
# 
# Notes:
# Channel ID is necessary to get pretty much any data, as almost all data is
# specific to a channel.

Sauce = require './sauce'
io    = require './ioutil'

mysql = require 'mysql'
fs    = require 'fs'

timeOutLimit = 30 * 60 * 1000
lastConnect = 0

client = null

# Connects to the MySQL database, disconnecting any previously connected
# database.
connect = ->
    io.debug "MySQL - Connecting"
    client?.destroy()
    
    client = mysql.createClient
            user     : Sauce.MySQL.Username
            password : Sauce.MySQL.Password
    
    client.useDatabase Sauce.MySQL.Database


# Sets up the database.
# This executes the SQL file located in Sauce.DBDump.
#
# * drop: Whether to drop existing tables.
# * err : A callback to call on error.
exports.setup = (drop, err) ->
    # Read .sql file
    file = Sauce.DBDump
    data = fs.readFileSync file, 'utf8'
    unless data?
        return err("Could not load db file \"#{file}\"")

    # Parse out comments and blank lines
    data = data.replace /^(\/\*.*\s*|--.*\s*|\s*)/mg, ''

    # Get a list of queries and statements
    stmts = data.split /;$\s*/m

    for stmt in stmts
        # Execute drop statements only if the "drop" flag is enabled.
        if /^DROP/.test stmt
            query(stmt, err) if drop

        # Make sure CREATE TABLE statements don't throw errors when
        # the "drop" flag is disabled.
        else if /^CREATE/.test stmt
            if not drop
                stmt = stmt.replace /^CREATE TABLE/, 'CREATE TABLE IF NOT EXISTS'

            query(stmt, err)

        # For unknown statements, just execute them blindly. :-)
        else if /^\w/.test stmt
            query(stmt, err)


# Returns whether more time than the timeout limit
# has passed since the last call to the query method.
timedOut = ->
    -lastConnect + (lastConnect = Date.now()) > timeOutLimit


# Performs a query, first checking if the database needs to be reconnected.
# As with timedOut, this check could be improved upon.
#
# Note: only the statement argument is necessary, with the parameters being
# potentially optional, and the callback always optional.
#
# * args: the arguments to pass to the MySQL client query function; in order,
#         the SQL statement, the parameters to the query,
#         and a callback function of the form (error, results) ->
exports.query = query = (args...) ->
    connect() if timedOut()
    client.query args...



# Loads all of the data for a specific channel from a specified table,
# then passing it to the given callback function.
#
# Note: at the moment, any errors encountered are just thrown.
#
# * channel : the channel id of the channel whose data is being requested.
# * table   : the table to search for the data.
# * callback: a function that takes the set of rows found as an argument.
exports.getChanData = (channel, table, callback) ->
    query(
        "SELECT * FROM #{table} WHERE chanid = ?",
        [channel], (err, results) ->
            throw err if err
            callback results
    )


# Similar to getChanData, but instead of having a single callback called at the
# end of the data retrieval, one callback is called for each row returned,
# and then an optional final callback is called.
#
# * channel : the channel id of the channel whose data is being requested
# * table   : the table containing the data being requested.
# * callback: a function taking a single row from the table as an argument,
#             to be called multiple times.
# * lastcb  : a no-argument function to be called after all of the data has been processed.
exports.getChanDataEach = (channel, table, callback, lastcb) ->
    exports.getChanData channel, table, (results) ->
        callback result for result in results
        lastcb() if lastcb


# Simply dumps everything from a table onto a callback function,
# throwing any error encountered.
#
# * table   : the table to retrieve content from.
# * callback: a callback that takes the set of rows returned as an argument.
exports.getData = (table, callback) ->
    query(
        "SELECT * FROM #{table}",
        (err, results) ->
            throw err if err # TODO
            callback results
    )

# A variation of getData, akin to getChanDataEach, that first fetches the data,
# then passes each row sequentially to a callback, and then executes an
# optional final callback.
#
# * table   : the table containing the data being requested.
# * callback: a function taking a single row from the table as an argument,
#             to be called multiple times
# * lastcb  : a no-argument function to be called after all of the data has been processed.
exports.getDataEach = (table, callback, lastcb) ->
    exports.getData table, (results) ->
        callback result for result in results
        lastcb() if lastcb


# Deletes all data in a given table about a specified channel id, running a
# callback on completion.
#
# * channel: the channel whose data is being cleared
# * table  : the table containing the data to be cleared
# * cb     : a callback without any arguments to be called after the deletion
exports.clearChanData = (channel, table, cb) ->
    query "DELETE FROM #{table} WHERE chanid = ?", [channel], cb


# Clears an entire table.
#
# * table: the table to empty.
exports.clearTable = (table) ->
    query "DELETE FROM #{table}"


# Removes all rows in a given table for a specified channel where the column
# specified by 'field' matches 'value', running a callback on completion.
#
# * channel: the channel whose data may be removed.
# * table  : the table to be affected by this remove.
# * field  : the field being used as a condition for the removal.
# * value  : the value for comparison to the field.
# * cb     : a no-argument callback to run after the deletion.
exports.removeChanData = (channel, table, field, value, cb) ->
    query "DELETE FROM #{table} WHERE #{field} = ? AND chanid = ?", [value, channel], cb


# Generates a string of comma-separated wildcard variables of a given length
# for use in queries.
#
# * num: the number of variables to generate.
getWildcards = (num) ->
    ('?' for [1..num]).join ', '


# For each row in datalist, adds a row containing the given fields set to the
# values in the datalist row, for a given channel, to the specified table, or
# replaces the row if it already exists.
#
# * channel : the channel which the data should be added to.
# * table   : the table to add the data to.
# * fields  : the columns being given values in the addition.
# * datalist: a set of rows each containing values corresponding to the specified columns.
exports.addChanData = (channel, table, fields, datalist, cb) ->
    exports.addData(table, ['chanid'].concat(fields), [channel].concat(data) for data in datalist, cb)


# Adds or replaces the rows defined by fields and datalist to the specified table.
#
# * table   : the table to add the data to.
# * fields  : the columns whose values are being set in the new rows.
# * datalist: the actual data of each row, labeled by fields.
exports.addData = (table, fields, datalist, cb) ->
    wc = getWildcards fields.length
    queryStr = "REPLACE INTO #{table} (`#{fields.join '`, `'}`) VALUES (#{wc})"
    callback = (err, results) -> cb?()
    query queryStr, data, callback for data in datalist


# Performs the same function as addChanData, but first clears all data for the
# channel in the specified table.
#
# * channel : the channel which the data should be added to.
# * table   : the table to add the data to.
# * fields  : the columns whose values are being set in the new rows.
# * datalist: the actual data of each row, labeled by fields.
exports.setChanData = (channel, table, fields, data) ->
    exports.clearChanData channel, table, ->
        exports.addChanData channel, table, fields, data


# Loads, for a given channel, either all of the values from a table in a
# specified column, or a mapping of the values in one "key" column to those in
# another column, and then passes the result to a callback.
#
# This can be thought of as either allowing JS to automatically index the data,
# or providing our own index, respectively.
#
# * channel : the channel to filter our data to.
# * table   : the table containing the desired data.
# * fields  : either the name of a column in the table, if we just want an array;
#             or an object with a key attribute specifying the column to be used
#             as the key in the result object, and a value attribute for the value to map to.
# * callback: a function taking the resulting data object as an argument.
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

# Loads a bucket, i.e., a map of the values of the key column to their corresponding row,
# for a channel in the specified table, and passes it to a callback.
#
# Note: may throw errors on database error.
#
# * channel : the channel containing the buckets.
# * table   : the table of the buckets.
# * key     : the name of the column which is to be used as a key in the resulting map.
# * callback: a function taking the result object mapping key values to rows as an argument .
exports.loadBucket = (channel, table, key, callback) ->
    query(
        "SELECT * FROM #{table} WHERE chanid = ?",
        [channel], (err, results) =>
            throw err if err # TODO
            data = {}
            data[result[key]] = result for result in results
            callback data
    )

