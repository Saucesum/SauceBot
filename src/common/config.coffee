# SauceBot Configuration File Reader

fs = require 'fs'

DEFAULT_DIR = '../../config'


# Attempts to load a JSON configurations file.
#
# * dir     : (optional) Where to find the config file.
# * confname: Name of configurations.
exports.load = (dir, confname) ->
    unless confname?
        confname = dir
        dir = DEFAULT_DIR

    fname = "#{dir}/#{confname}"
    
    try
        filedata = fs.readFileSync fname, 'utf-8'
        config   = JSON.parse filedata
    catch error
        throw new Error("Error in configuration file #{fname}: " + error)
    
