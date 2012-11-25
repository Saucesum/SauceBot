# Tests for the database query generator

db = require '../../server/db/sqlgen'

describe 'QueryGenerator', ->
    describe 'update', ->
        it 'should return a basic update query', ->
            db.update('commands').query.should.equal('UPDATE `commands`')

        it 'should throw an error when no table is specified', ->
            try
                db.update()
                assert false
            catch err
                err.should.equal 'No table specified'

        it 'should add "set" values', ->
            expected = 'UPDATE `commands` SET `cmdtrigger`=?'
            db.update('commands').set('cmdtrigger', 'hello').query.should.equal expected

        it 'should only add one "SET"', ->
            upd = db.update 'commands'
            expected = 'UPDATE `commands` SET `cmdtrigger`=? ,`msg`=?'
            upd.set('cmdtrigger', 'asdf').set('msg', 'lolol').query.should.equal expected

        it 'should add a "where" clause', ->
            expected = 'UPDATE `tests` WHERE `chanid`=?'
            db.update('tests').where('chanid', 5).query.should.equal expected

        it 'should only add one "WHERE"', ->
            upd = db.update 'tests'
            expected = 'UPDATE `tests` WHERE `chanid`=? AND `cmdtrigger`=?'
            upd.where('chanid', 5).where('cmdtrigger', 'hello').query.should.equal expected

        it 'should allow mixing of where and set', ->
            upd = db.update 'news'
            expected = 'UPDATE `news` SET `message`=? WHERE `chanid`=? AND `newsid`=?'
            upd.set('message', 'hello!').where('chanid', 3).where('newsid', 23).query.should.equal expected

        it 'should add values in the right order', ->
            upd = db.update 'counters'
            expected = [42, 'lives', 1, 'deaths']
            actual   = upd.set('value', 42).set('name', 'lives').where('chanid', 1).where('name', 'deaths').valuelist
            actual.length.should.equal expected.length
            actual[i].should.equal expected[i] for i in [0..expected.length-1]

    describe 'delete', ->
        it 'should return a basic delete query', ->
            db.delete('tests').query.should.equal('DELETE FROM `tests`')
            
        it 'should add a "WHERE" clause', ->
            expected = 'DELETE FROM `asdfs` WHERE `chanid`=?'
            db.delete('asdfs').where('chanid', 99).query.should.equal expected

        it 'should only add one "WHERE"', ->
            expected = 'DELETE FROM `cakes` WHERE `name`=? AND `type`=?'
            db.delete('cakes').where('name', 'frank').where('type', 'chocolate').query.should.equal expected

    describe 'insert', ->
        it 'should return a basic insert query', ->
            db.insert('names').query.should.equal 'INSERT INTO `names`'

        it 'should add a fields list', ->
            db.insert('names').fields('chanid', 'level', 'name').query.should.equal 'INSERT INTO `names` (`chanid`,`level`,`name`)'

        it 'should add a value list', ->
            expected = [7, 'hello', 'Hello world!']
            ins = db.insert('commands').values(expected...)
            ins.query.should.equal 'INSERT INTO `commands` VALUES (?,?,?)'
            actual = ins.valuelist
            actual[i].should.equal expected[i] for i in [0..expected.length-1]

        it 'should combine field and value list', ->
            fields = ['chanid', 'cmdtrigger', 'msg']
            values = [5, 'test', 'Test command! :-D']
            expected = 'INSERT INTO `commands` (`chanid`,`cmdtrigger`,`msg`) VALUES (?,?,?)'
            ins = db.insert('commands').fields(fields...).values(values...)
            ins.query.should.equal expected
            ins.fieldlist[i].should.equal fields[i] for i in [0..fields.length-1]
            ins.valuelist[i].should.equal values[i] for i in [0..values.length-1]

    describe 'replace', ->
        it 'should return a basic replace query', ->
            db.replace('users').query.should.equal 'REPLACE INTO `users`'

    describe 'select', ->
        it 'should return a basic select query', ->
            db.select('channels').query.should.equal 'SELECT * FROM `channels`'

        it 'should add a where clause', ->
            expected = 'SELECT * FROM `channels` WHERE `chanid`=?'
            sel = db.select('channels').where('chanid', 6)
            sel.query.should.equal expected
            sel.fieldlist[0].should.equal 'chanid'
            sel.valuelist[0].should.equal 6

        it 'should allow multiple where clauses', ->
            expected = 'SELECT * FROM `names` WHERE `type`=? AND `prop`=?'
            sel = db.select('names').where('type', 'cat').where('prop', 'awesome')
            sel.query.should.equal expected
            sel.valuelist[0].should.equal 'cat'
            sel.valuelist[1].should.equal 'awesome'
