# SQL Query Generator

createQuery = (table, type) ->
    unless table? and type?
        throw 'No table specified'

    o = {
        table: table
        type : type
        query: "#{type} `#{table}`"

        fieldlist: []
        valuelist: []

        hasSet  : false
        hasWhere: false

        # Private methods

        add: (sql) ->
            o.query += " #{sql}"
            o

        field: (key, val) ->
            o.fieldlist.push key
            o.valuelist.push val

        # Public methods

        commit: ->
            query obj.query
            o

        # SET key1=val1, key2=val2, ...
        set: (key, val) ->
            o.field key, val

            if o.hasSet
                o.add ",`#{key}`=?"
            else
                o.add "SET `#{key}`=?"
                o.hasSet = true

            o

        # WHERE key1=val1 AND key2=val2, ...
        where: (key, val) ->
            o.field key, val

            if o.hasWhere
                o.add "AND `#{key}`=?"
            else
                o.add "WHERE `#{key}`=?"
                o.hasWhere = true

            o

        # (key1,key2,key3, ...)
        fields: (keys...) ->
            o.fieldlist.push key for key in keys
            o.add '(`' + keys.join('`,`') + '`)'
            o

        # VALUES (val1,val2,val3, ...)
        values: (vals...) ->
            o.valuelist.push val for val in vals
            o.add 'VALUES (' + ('?' for _ in [1..vals.length]).join(',') + ')'
            o

    }

exports[k] = v for k, v of {
    update : (table) -> createQuery table, 'UPDATE'
    delete : (table) -> createQuery table, 'DELETE FROM'
    insert : (table) -> createQuery table, 'INSERT INTO'
    replace: (table) -> createQuery table, 'REPLACE INTO'
    select : (table) -> createQuery table, 'SELECT * FROM'
}

