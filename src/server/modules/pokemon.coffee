# SauceBot Module: Pokemon Fun Time

Sauce = require '../sauce'
db    = require '../saucedb'
io    = require '../ioutil'

{Module} = require '../module'

# Module description
exports.name        = 'Pokemon'
exports.version     = '1.0'
exports.description = 'Pokèmon catching game.'
exports.ignore      = true

# Module strings
exports.strings = {
    
}

io.module '[Pokemon] Init'

MIN_LEVEL = 1
MAX_LEVEL = 100

# Mon-map for teams.
# Maps username to Mon list.
teams = {}


# Returns a random user from the list.
randUser = (list) ->
    if list.length > 0
        list.random()
    else
        'MissingNo.'


randChance = (chance) -> Math.random() < chance

class Mon
    constructor: (@name) ->
        @level = 0
        @attr  = {}

        @setRandomLevel()
        @generateRandomAttributes()


    # Sets the mon's level to a random value.
    setRandomLevel: ->
        diff = MAX_LEVEL - MIN_LEVEL
        @level = ~~(Math.random() * diff) + MIN_LEVEL


    # Randomly adds special attributes.
    generateRandomAttributes: ->
        @addAttribute 'shiny' if randChance(0.05)
        @addAttribute 'rus'   if randChance(0.01)


    # Adds a special attribute to the mon
    addAttribute: (attr) ->
        @attr[attr] = true


    # Returns a short string representation of the mon.
    str: ->
        str = @name
        str += '?' if @attr.rus
        str += '^' if @attr.shiny
        str += "[LV#{@level}]"


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

    team.pop()


natures = [
    'evil', 'mean', 'crazy', 'happy', 'cute',
    'pretty', 'beautiful', 'amazing', 'sleepy',
    'weird', 'funny', 'boring', 'lame', 'silly',
    'neat', 'fun', 'enjoyable', 'pleasing',
    'appealing', 'dumb', 'awesome', 'stupid',
    'friendly', 'freaky', 'elegant', 'rich'
]

# Returns a random nature.
getRandomNature = ->
    natures.random()


failures = [
    'Almost had it!'
    'Not even close.'
    'It broke free!'
    'So close!'
]

# Returns a random failure description.
getRandomFailure = ->
        failures.random()


# Pokemon module
class Pokemon extends Module
    constructor: (@channel) ->
        super @channel

        
    load: (chan) ->
        @channel = chan if chan?
        
        @regCmd 'pm', @cmdPkmn
        @regCmd 'pm team', @cmdTeam
        @regCmd 'pm throw', @cmdThrow
        @regCmd 'pm release', @cmdRelease
        @regCmd 'pm release all', @cmdReleaseAll

        @regActs {
            'get': (user, args, res) =>
                {user} = args
                res.send teams[user.name.toLowerCase()] ? []
        }


    # !pm
    cmdPkmn: (user, args, bot) =>
        @say bot, "Usage: !pm <cmd>. Commands: team, throw, release"


    # !pm team
    cmdTeam: (user, args, bot) =>
        user = user.name
        unless (team = teams[user.toLowerCase()])?
            return @say bot, "#{user} has no team! Catch pokemon with !pm throw"

        str = (mon.str() for mon in team).join (', ')
        @say bot, "#{user}'s team: #{str}"


    # !pm throw [user]
    cmdThrow: (user, args, bot) =>
        user = user.name
        unless (team = teams[user.toLowerCase()])?
            team = teams[user.toLowerCase()] = []

        mon = createPokemon @channel
        if args[0]?
            mon.name = args[0]

        result = ''
        

        rand = Math.random()
        if rand < 0.3 - (mon.level/1000.0)
            # Caught!
            if team.length >= 6
                result = "Full team! Release with !pm release [all]"
            else
                team.push mon
                result = "Got it! Nature: " + getRandomNature()
        else
            result = getRandomFailure()
            
        @say bot, "#{user}: #{mon.fullStr()}! #{result}"
            

    # !pm release
    cmdRelease: (user, args, bot) =>
        user = user.name
        unless (team = teams[user.toLowerCase()])? and team.length > 0
            return @say bot, "#{user} has no team! Catch pokemon with !pm throw"

        mon = removeRandom team
        @say bot, "#{user} released a #{mon.fullStr()}"


    # !pm release all
    cmdReleaseAll: (user, args, bot) =>
        user = user.name
        unless (team = teams[user.toLowerCase()])? and team.length > 0
            return @say bot, "#{user} has no team!"

        namestr = (mon.name for mon in team).join(', ')
        delete teams[user.toLowerCase()]
        @say bot, "#{user} put #{namestr} to sleep ... You evil person."


    say: (bot, msg) ->
        bot.say '[Pkmn] ' + msg


exports.New = (channel) ->
    new Pokemon channel

