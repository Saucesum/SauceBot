# SauceBot Module: Pokemon Fun Time

Sauce = require '../sauce'
db    = require '../saucedb'
io    = require '../ioutil'

{Module}    = require '../module'
{ConfigDTO} = require '../dto'

# Module description
exports.name        = 'Pokemon'
exports.version     = '1.2'
exports.description = 'Pokèmon catching game.'
exports.ignore      = true

# Module strings
exports.strings = {
    name: 'Pkmn'

    'fail-1': 'Almost had it!'
    'fail-2': 'Not even close.'
    'fail-3': 'It broke free!'
    'fail-4': 'So close!'

    'modonly-enabled':  'Set to moderator-only mode.'
    'modonly-disabled': 'Moderator-only mode disabled.'

    'err-usage'   : 'Usage: @1@'
    'err-commands': 'Commands: @1@'

    'err-no-team'       : '@1@ has no team!'
    'err-catch-usage'   : 'Catch pokemon with @1@'
    'err-unknown-user'  : 'I can\'t find @1@. :-('
    'err-full-team'     : 'Full team! Release with @1@'
    'err-duplicate-user': 'You have already caught that pokemon!'
    'err-weirdo'        : '@1@: You can\'t play with yourself!'
    'err-bully'         : 'You bully!'

    'action-team'      : '@1@\'s team: @2@'
    'action-catch'     : 'Got it! Nature: @1@'
    'action-release'   : '@1@ released @2@'
    'action-releaseall': '@1@ put @2@ to sleep ... You evil person.'
    'action-stats'     : '@1@: @2@% - @3@ won - @4@ lost - @5@ draw.'
    'action-top'       : 'Masters: @1@'

    'battle-levelup'   : '@1@ levels up!'
    'battle-win'       : '@1@ was victorious!'
    'battle-lose'      : '@1@ was defeated!'
    'battle-draw'      : 'It\'s a draw!'
    
}

io.module '[Pokemon] Init'

# Pokemon generator level-boundaries
MIN_LEVEL = 1
MAX_LEVEL = 100

# Battle chances
DRAW_CHANCE = 4
WIN_MIN_PERCENTAGE  = 50 + DRAW_CHANCE/2
LOSS_MAX_PERCENTAGE = 50 - DRAW_CHANCE/2

# Max team size
TEAM_MAX  = 6

# Mon-map for teams.
# Maps username to Mon list.
teams = {}

# Battle data
fights = {}


# Returns a random user from the list.
randUser = (list) ->
    if list.length > 0
        list.random()
    else
        'MissingNo.'



# Returns the sum of each element in the array
sum = (arr) ->
    n = 0
    n += v for v in arr
    return n


getSortedTopTeams = (n) ->
        names = Object.keys teams
        levels = {}
        levels[name] = sum(mon.level for mon in teams[name]) for name in names
        sorted = (names.sort (a, b) -> levels[b] - levels[a])
        return ([u, levels[u]] for u in sorted[0..n-1])


getExpForLevel = (lvl) ->
    return NaN if lvl > 100
    return Math.pow(lvl, 0.75) * 10


randChance = (chance) -> Math.random() < chance

natures = [
    'evil', 'mean', 'crazy', 'happy', 'cute',
    'pretty', 'beautiful', 'amazing', 'sleepy',
    'weird', 'funny', 'boring', 'lame', 'silly',
    'neat', 'fun', 'enjoyable', 'pleasing', 'tall',
    'appealing', 'dumb', 'awesome', 'stupid',
    'friendly', 'freaky', 'elegant', 'rich', 'odd',
    'lucky', 'young', 'old', 'unknown', 'confused',
    'forgetful', 'talkative', 'mature', 'immature',
    'strong', 'weak', 'malnourished', 'hungry',
    'dying', 'super', 'naughty', 'short', 'toothless'
]

class Mon
    constructor: (@name, data) ->
        @id     = -1
        @level  = 0
        @nature = ''
        @attr   = {}

        @exp = 0

        if data?
            @id     = data.id
            @level  = data.level
            @nature = data.nature
            @attr   = data.attr
        else
            @setRandomLevel()
            @generateRandomAttributes()


    # Sets the mon's level to a random value.
    setRandomLevel: ->
        diff = (MAX_LEVEL - MIN_LEVEL) + 1
        @level = ~~(Math.random() * diff) + MIN_LEVEL


    # Randomly adds special attributes.
    generateRandomAttributes: ->
        @nature = natures.random()
        @addAttribute attr for attr of AttrUtil.random()


    # Adds a special attribute to the mon
    addAttribute: (attr) ->
        @attr[attr] = true


    # Gives experience to the mon, and levels up if possible.
    # = returns the level difference
    addExperience: (exp) ->
        @exp += exp
        levelStart = @level
        while (@exp > (needed = getExpForLevel(@level + 1)))
            @exp -= needed
            @level += 1

        return @level - levelStart
    

    # Updates the mon's level in the database
    save: ->
        db.query "UPDATE pkmn SET level=? WHERE id=?", [@level, @id]
        

    # Returns a short string representation of the mon.
    str: ->
        str = @name
        str += '?' if @attr.rus
        str += '^' if @attr.shiny
        str += "[#{@level}]"


    # Returns a more descriptive representation of the mon.
    fullStr: ->
        str = ''
        str += 'shiny '   if @attr.shiny
        str += "pokerus " if @attr.rus
        str += "level #{@level} "
        str += "#{@name}"
        

# Generates a new pokeman.
createPokemon = (chan) ->
    mon = new Mon randUser Object.keys(chan.usernames)


# Removes and returns a random element from the team.
# Note that this does not maintain the original team order.
removeRandom = (team) ->
    max    = team.length - 1
    idx    = team.randomIdx()
    
    # Swap the last element with The Chosen One
    [team[idx], team[max]] = [team[max], team[idx]]

    mon = team.pop()
    if mon.id > -1
        db.query "DELETE FROM pkmn WHERE id=?", [mon.id]
    return mon


# Removes all pokemon from the specified person's team
removeAll = (name) ->
    name = name.toLowerCase()
    delete teams[name]
    db.query "DELETE FROM pkmn WHERE owner=?", [name]


failures = [ 'fail-1', 'fail-2', 'fail-3', 'fail-4' ]

# Returns a random failure description.
getRandomFailure = ->
        failures.random()


statsFor = (user) ->
    user = user.toLowerCase()
    return stats if (stats = fights[user])?

    return fights[user] = {
        won    : 0
        lost   : 0
        draw   : 0
    }


# Utility methods for pokemon attributes
AttrUtil = {
    # Deserializes a database attrs string to an object
    deserialize: (str) ->
        attrs = {}
        for i in [0..str.length-1]
            switch str[i]
                when 'S' then attrs.shiny = true
                when 'R' then attrs.rus   = true
        return attrs


    # Serializes an attrs object to a database ready string
    serialize: (attrs) ->
        str = ''
        str += 'S' if attrs.shiny
        str += 'R' if attrs.rus
        return str

    random: ->
        attrs = {}
        attrs.shiny = true if randChance(0.05)
        attrs.rus   = true if randChance(0.01)
        return attrs

}

# Loads persistent data
(loadData = ->
    # Load trainer data
    db.query "SELECT * FROM pkmntrainer", (err, data) ->
        # { name, won, lost, draw }
        fights = {}
        for fight in data
            fights[fight.name] = {
                won : fight.won
                lost: fight.lost
                draw: fight.draw
            }
        io.debug "[PKMN] Loaded data for #{data.length} trainers"


    # Load monster data
    db.query "SELECT * FROM pkmn", (err, data) ->
        # { id, owner, name, level, nature, attrs }
        for mon in data
            {id, owner, name, level, nature, attrs} = mon
            attr = AttrUtil.deserialize attrs

            unless (team = teams[owner])?
                team = teams[owner] = []

            team.push new Mon name, {
                id    : id
                nature: nature
                level : level
                attr  : attr
            }

        io.debug "[PKMN] Loaded #{data.length} pokemons"
)()

runDecayation = ->
    io.debug "Decaying pokemon levels ..."
    for name, team of teams
        decay team


decay = (team) ->
    i = 0
    while i < team.length
        mon = team[i]
        if mon.level > 1
            mon.level = mon.level - 1
            mon.save()
        else
            db.query "DELETE FROM pkmn WHERE id=?", [mon.id]
            team.splice(i, 1)

        i = i + 1


MS_PER_DAY = 1000 * 60 * 60 * 24
decayer = ->
    setTimeout( ->
        runDecayation()
        decayer()
    , (MS_PER_DAY / 2))


decayer()

saveStats = (name, stats) ->
    name = name.toLowerCase()
    data = [name, stats.won, stats.lost, stats.draw]
    db.query "REPLACE INTO pkmntrainer (name, won, lost, draw) VALUES (?,?,?,?)", data


addToTeam = (name, mon) ->
    name = name.toLowerCase()
    unless (team = teams[name])?
        team = teams[name] = []

    team.push mon
    data = [name, mon.name, mon.level, mon.nature, AttrUtil.serialize(mon.attr)]
    db.query "INSERT INTO pkmn (owner, name, level, nature, attrs) VALUES (?,?,?,?,?)", data, (err, res) ->
        if err? then throw err
        mon.id = res.insertId



# Pokemon module
class Pokemon extends Module
    constructor: (@channel) ->
        super @channel

        @conf = new ConfigDTO @channel, 'pokemonconf', ['modonly']

        
    load: (chan) ->
        @channel = chan if chan?

        @conf.load()

        @regCmd 'pm',             @cmdPkmn
        @regCmd 'pm team',        @cmdTeam
        @regCmd 'pm throw',       @cmdThrow
        @regCmd 'pm release',     @cmdRelease
        @regCmd 'pm release all', @cmdReleaseAll
        @regCmd 'pm stats',       @cmdStats
        @regCmd 'pm fight',       @cmdFight
        @regCmd 'pm top',         @cmdTop

        @regCmd 'pm modonly', Sauce.Level.Mod, (user, args) =>
            enable = args[0]

            if enable is 'on'
                @conf.add 'modonly', 1
                @say @str('modonly-enabled')
            else if enable is 'off'
                @conf.add 'modonly', 0
                @say @str('modonly-disabled')
            else
                @say @str('err-usage', '!pm modonly on/off')


        @regActs {
            # Returns either the list of trainers or the specified trainer's team
            'get': (user, args, res) =>
                {name} = args
                if name?
                    name = name.toLowerCase()
                    res.send team: (teams[name] ? []), stats: fights[name]
                else
                    res.send Object.keys(teams)

            # Returns the top: strongest pokemon trainers
            'top': (user, args, res) =>
                res.send getSortedTopTeams(10)
        }


    notPermitted: (user) ->
        return unless @conf.get('modonly')
        return not user.op

    # !pm
    cmdPkmn: (user, args) =>
        return if @notPermitted user
        @say @str('err-usage', '!pm <cmd>. Commands: team, throw, release, fight, stats, top, modonly')


    # !pm team
    cmdTeam: (user, args) =>
        return if @notPermitted user
        user = user.name
        unless (team = teams[user.toLowerCase()])?
            return @say @str('err-no-team', user) + ' ' + @str('err-catch-usage', '!pm throw')

        str = (mon.str() for mon in team).join (', ')
        @say @str('action-team', user, str)


    # !pm throw [user]
    cmdThrow: (user, args) =>
        return if @notPermitted user
        user = user.name
        mon  = createPokemon @channel
        if args[0]?
            targetName = args[0].toLowerCase()
            if @channel.usernames[targetName]?
                mon.name = targetName
            else
                return @say "#{user}: " + @str('err-unknown-user', targetName)

        result = try
            @catchPokemon user, mon
            @str('action-catch', mon.nature)
        catch err then err
            
        @say "#{user}: #{mon.fullStr()}! #{result}"


    catchPokemon: (user, mon) ->
        team = teams[user.toLowerCase()]
        if team?
            if team.length >= TEAM_MAX
                throw @str('err-full-team', '!pm release [all]')
            for teamMon in team when teamMon.name is mon.name
                throw @str('err-duplicate-user')

        if randChance(0.3 - (mon.level/1000.0))
            # Caught!
            addToTeam user, mon
        else
            throw @str(getRandomFailure())
            

    # !pm release
    cmdRelease: (user, args) =>
        return if @notPermitted user
        user = user.name
        unless (team = teams[user.toLowerCase()])? and team.length > 0
            return @say @str('err-no-team', user) + ' ' + @str('err-catch-usage', '!pm throw')

        mon = removeRandom team
        @say @str('action-release', user, mon.fullStr())


    # !pm release all
    cmdReleaseAll: (user, args) =>
        return if @notPermitted user
        user = user.name
        unless (team = teams[user.toLowerCase()])? and team.length > 0
            return @say @str('err-no-team', user)

        namestr = (mon.name for mon in team).join(', ')
        removeAll user
        @say @str('action-releaseall', user, namestr)


    # !pm stats
    cmdStats: (user, args) =>
        return if @notPermitted user
        user = user.name
        stats = statsFor user
        {won, lost, draw} = stats
        ratio = ~~((won / (won+lost+draw)) * 100)
        @say @str('action-stats', user, ratio, won, lost, draw)


    # !pm top
    cmdTop: (user, args) =>
        return if @notPermitted user
        top = getSortedTopTeams(10)
        topStr = (k[0] + "(" + k[1] + ")" for k in top).join(', ')
        @say @str('action-top', topStr)
   

    # !pm fight (target)
    cmdFight: (user, args) =>
        return if @notPermitted user
        user = user.name

        unless (target = args[0])?
            return @say @str('err-usage', '!pm fight <user>')

        message = try
            battle = new PokeBattle user, target, (args...) => @str(args...)
            battle.checkTeams()
            battle.getResult()
        catch err then err

        @say message
        

class PokeBattle
    constructor: (userName, targetName, @str) ->
        userName   = userName.toLowerCase()
        targetName = targetName.toLowerCase()

        if userName is targetName
            throw @str('err-weirdo', userName)

        @user   = @getUserObject userName
        @target = @getUserObject targetName


    getUserObject: (name) ->
        return {
            name : name
            team : teams[name]
            stats: statsFor name
        }


    checkTeams: ->
        unless @hasTeam @user
            throw @str('err-no-team', @user.name) + ' ' + @str('err-catch-usage', '!pm throw')
        unless @hasTeam @target
            throw @str('err-no-team', @target.name) + ' ' + @str('err-bully')


    hasTeam: (obj) ->
        return obj.team? and obj.team.length > 0


    getResult: ->
        userMon   = @user.team.random()
        targetMon = @target.team.random()
        
        vs = "#{@user.name}'s #{userMon.str()} vs. #{@target.name}'s #{targetMon.str()}!"

        rand = @getRandomResult userMon, targetMon

        userExp   = 0
        targetExp = 0

        result = if rand > WIN_MIN_PERCENTAGE
            userExp = targetMon.level
            @handleWin()
        else if rand < LOSS_MAX_PERCENTAGE
            targetExp = userMon.level
            @handleLoss()
        else
            userExp   = targetMon.level / 2
            targetExp = userMon.level / 2
            @handleDraw()
        
        @saveStatsFor @user
        @saveStatsFor @target

        dingers = []

        if userMon.addExperience userExp
            dingers.push userMon.name
            userMon.save()
        if targetMon.addExperience targetExp
            dingers.push targetMon.name
            targetMon.save()


        message = "#{vs} #{result}"
        if dingers.length > 0
            message += ' '  + @str('battle-levelup', dingers.join(', '))

        return message


    handleWin: ->
        @user.stats.won++
        @target.stats.lost++
        return @str('battle-win', @user.name)


    handleLoss: ->
        @user.stats.lost++
        @target.stats.won++
        return @str('battle-lose', @user.name)


    handleDraw: ->
        @user.stats.draw++
        @target.stats.draw++
        return @str('battle-draw')


    saveStatsFor: (obj) ->
        saveStats obj.name, obj.stats


    getRandomResult: (mon1, mon2) ->
        diff = mon2.level - mon1.level
        return (Math.random() * 100) - (diff/2.1)
        
    

exports.New = (channel) ->
    new Pokemon channel

