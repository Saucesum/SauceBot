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
        diff = MAX_LEVEL - MIN_LEVEL
        @level = ~~(Math.random() * diff) + MIN_LEVEL


    # Randomly adds special attributes.
    generateRandomAttributes: ->
        @nature = natures.random()
        @addAttribute attr for attr of AttrUtil.random()


    # Adds a special attribute to the mon
    addAttribute: (attr) ->
        @attr[attr] = true


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


failures = [
    'Almost had it!'
    'Not even close.'
    'It broke free!'
    'So close!'
]

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
            db.query "UPDATE pkmn SET level=? WHERE id=?", [mon.level, mon.id]
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

    if team.length >= TEAM_MAX
        return false

    team.push mon
    data = [name, mon.name, mon.level, mon.nature, AttrUtil.serialize(mon.attr)]
    db.query "INSERT INTO pkmn (owner, name, level, nature, attrs) VALUES (?,?,?,?,?)", data, (err, res) ->
        if err? then throw err
        mon.id = res.insertId
    return true



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

        @regCmd 'pm modonly', Sauce.Level.Mod, (user, args, bot) =>
            enable = args[0]

            if enable is 'on'
                @conf.add 'modonly', 1
                @say bot, 'Set to moderator-only.'
            else if enable is 'off'
                @conf.add 'modonly', 0
                @say bot, 'Moderator-only disabled.'
            else
                @say bot, 'Usage: !pm modonly on/off'


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
    cmdPkmn: (user, args, bot) =>
        return if @notPermitted user
        @say bot, "Usage: !pm <cmd>. Commands: team, throw, release, fight, stats, modonly"


    # !pm team
    cmdTeam: (user, args, bot) =>
        return if @notPermitted user
        user = user.name
        unless (team = teams[user.toLowerCase()])?
            return @say bot, "#{user} has no team! Catch pokemon with !pm throw"

        str = (mon.str() for mon in team).join (', ')
        @say bot, "#{user}'s team: #{str}"


    # !pm throw [user]
    cmdThrow: (user, args, bot) =>
        return if @notPermitted user
        user = user.name

        mon = createPokemon @channel
        if args[0]?
            targetName = args[0].toLowerCase()
            if @channel.usernames[targetName]?
                mon.name = targetName
            else
                return @say bot, "#{user}: I can't find #{targetName}. :-("

        result = ''
        

        rand = Math.random()
        if rand < 0.3 - (mon.level/1000.0)
            # Caught!
            if addToTeam user, mon
                result = "Got it! Nature: " + mon.nature
            else
                result = "Full team! Release with !pm release [all]"
        else
            result = getRandomFailure()
            
        @say bot, "#{user}: #{mon.fullStr()}! #{result}"
            

    # !pm release
    cmdRelease: (user, args, bot) =>
        return if @notPermitted user
        user = user.name
        unless (team = teams[user.toLowerCase()])? and team.length > 0
            return @say bot, "#{user} has no team! Catch pokemon with !pm throw"

        mon = removeRandom team
        @say bot, "#{user} released a #{mon.fullStr()}"


    # !pm release all
    cmdReleaseAll: (user, args, bot) =>
        return if @notPermitted user
        user = user.name
        unless (team = teams[user.toLowerCase()])? and team.length > 0
            return @say bot, "#{user} has no team!"

        namestr = (mon.name for mon in team).join(', ')
        removeAll user
        @say bot, "#{user} put #{namestr} to sleep ... You evil person."


    # !pm stats
    cmdStats: (user, args, bot) =>
        return if @notPermitted user
        user = user.name
        stats = statsFor user
        {won, lost, draw} = stats
        ratio = ~~((won / (won+lost+draw)) * 100)
        @say bot, "#{user}: #{ratio}% - #{won} won - #{lost} lost - #{draw} draw."


    # !pm top
    cmdTop: (user, args, bot) =>
        return if @notPermitted user
        top = getSortedTopTeams(10)
        @say bot, "Masters: " + (k[0] + "(" + k[1] + ")" for k in top).join(', ')
   

    # !pm fight (target)
    cmdFight: (user, args, bot) =>
        return if @notPermitted user
        user = user.name

        unless (target = args[0])?
            return @say bot, "Fight usage: !pm fight <user>"

        message = try
            battle = new PokeBattle user, target
            battle.checkTeams()
            battle.getResult()
        catch err then err

        @say bot, message
        

class PokeBattle
    constructor: (userName, targetName) ->
        userName   = userName.toLowerCase()
        targetName = targetName.toLowerCase()

        if userName is targetName
            throw "#{userName}: You can't play with yourself!"

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
            throw "#{@user.name} doesn't have a team! Catch with !pm throw"
        unless @hasTeam @target
            throw "#{@target.name} doesn't have a team. You bully!"


    hasTeam: (obj) ->
        return obj.team? and obj.team.length > 0


    getResult: ->
        userMon   = @user.team.random()
        targetMon = @target.team.random()

        rand = @getRandomResult userMon, targetMon

        result = if rand > WIN_MIN_PERCENTAGE
            @handleWin()
        else if rand < LOSS_MAX_PERCENTAGE
            @handleLoss()
        else
            @handleDraw()
        
        @saveStatsFor @user
        @saveStatsFor @target

        vs = "#{@user.name}'s #{userMon.str()} vs. #{@target.name}'s #{targetMon.str()}!"

        return "#{vs} #{result}"


    handleWin: ->
        @user.stats.won++
        @target.stats.lost++
        return "#{@user.name} was victorious!"


    handleLoss: ->
        @user.stats.lost++
        @target.stats.won++
        return "#{@user.name} was defeated!"


    handleDraw: ->
        @user.stats.draw++
        @target.stats.draw++
        return "It's a draw!"


    saveStatsFor: (obj) ->
        saveStats obj.name, obj.stats


    getRandomResult: (mon1, mon2) ->
        diff = mon2.level - mon1.level
        return (Math.random() * 100) - (diff/2.1)
        
    

exports.New = (channel) ->
    new Pokemon channel

