# SauceBot Configuration File Reader

fs = require 'fs'

exports.load = (confname) ->
    fname = "../../config/#{confname}.json"
    
    try
        filedata = fs.readFileSync fname, 'utf-8'
        config   = JSON.parse filedata
    catch error
        throw new Error("Error in configuration file #{fname}: " + error)
    
