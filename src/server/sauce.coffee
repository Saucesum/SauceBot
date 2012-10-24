# SauceBot Configurations

io = require '../common/ioutil'

try
    conf = require('../common/config').load '.', 'server'
catch error
    io.error "Error in configuration file 'server'"
    process.exit 1

exports.Version = '3.2'
exports.Name    = conf.name


# Connection info
exports.PORT = conf.port

# FS
exports.Path = conf.logging.root


# Moderator levels
exports.Level =
    User : 0
    Mod  : 1
    Admin: 2
    Owner: 3

exports.LevelStr = (level) ->
    switch level
        when exports.Level.User  then 'User'
        when exports.Level.Mod   then 'Moderator'
        when exports.Level.Admin then 'Administrator'
        when exports.Level.Owner then 'Owner'
        else
            if level > exports.Level.Owner then 'Global' else 'None'



# Database configuration
exports.DB = conf.mysql
