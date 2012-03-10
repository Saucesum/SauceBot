# SauceBot Configurations

exports.Version = '3.0 BETA'
exports.Name    = 'SauceBot'


# Connection info
exports.PORT = 8455

# FS
exports.Path = process.env.HOME + '/' + exports.Name + '/'


# Moderator levels
exports.Level =
    User : 0
    Mod  : 1
    Admin: 2
    Owner: 3


# Database configuration
exports.DB =
    username: 'sauce'
    password: 'vz6ns4ygd'
    database: 'saucebot'
