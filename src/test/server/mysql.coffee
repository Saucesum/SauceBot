# MySQL tests

my = require '../../server/db/mysql'

db = new my.DBMySQL

chanid = 3

describe 'MySQL', ->
    describe 'get', ->
        it 'should return a get-query', ->
            db.get('commands').query.should.equal 'SELECT * FROM `commands`'

        it 'should return a get-query for a channel', ->
            db.getChan(chanid, 'commands').query.should.equal 'SELECT * FROM `commands` WHERE `chanid`=?'

    describe 'add', ->
        it 'should return a query for adding data', ->
            expected = 'INSERT INTO `commands` (`chanid`,`cmdtrigger`,`msg`) VALUES (?,?,?)'
            q = db.addData('commands', ['chanid', 'cmdtrigger', 'msg'], [chanid, 'hello', 'Hello World!'])
            q.query.should.equal expected

    
