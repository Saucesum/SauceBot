# SauceBot Configurations

io = require '../common/ioutil'

try
    conf = require('../common/config').load 'server'
catch error
    io.error "Error in configuration file 'server'"
    process.exit 1

exports.Version = '3.0 BETA'
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


# Database configuration
exports.DB = conf.mysql
