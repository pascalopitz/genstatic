#includes
coffee = require "coffee-script"
vm = require "vm"
_ = require "underscore"
fs = require "fs"
eco = require "eco"

sitePath = assetPath = outPath = dataPath = templatePath = null

# defaul config
config =
    extension : '.html'
    templates : './templates'
    assets : './assets'
    data : './data'
    output : './www'

# defaul helpers
helpers = 
    partial : (str) ->
        pcontent = fs.readFileSync templatePath + '/' + str + config.extension
        eco.render pcontent.toString(), this

# add custom helpers
addHelpers = () ->
    try
        str = fs.readFileSync sitePath + '/helpers.coffee'
        js = coffee.compile str.toString(), bare: 1
        vm.runInNewContext js, helpers
    catch e
        console.log e.toString()
        
# compiles a file from the data directory
compile = (filename, content, basedir) ->
    fname = filename.replace dataPath, ''
    
    # get embedded config
    reg = /^---\n([\W\w]*)\n---\n/gim
    matches = reg.exec content
    
    fconfig = 
        template : "index"

    try
        if(matches)
            content = content.replace matches[0], ''
            js = coffee.compile matches[1], bare: 1
            vm.runInNewContext js, fconfig
    catch e
        console.log "Not a valid file"
    null
    
    # set filename and basedir
    env = 
        filename : fname
        basedir : basedir

    template = templatePath + '/' + fconfig.template + config.extension

    # read template file, render template and content
    fs.readFile template, (err, tcontent) ->
        content = eco.render content, 
            _.extend {}, config, fconfig, helpers, env
            
        output = eco.render tcontent.toString(), 
            _.extend {}, config, fconfig, helpers, env, content: content

        fs.writeFile (outPath + fname), output, 'utf-8', (err) ->
            if(err)
                console.log err
        
# parses directories recusively
parseDir = (dir, depth) ->
    depth ?= 0
    console.log "parsing " + dir

    basepath = (i) ->
        path = ''
        while i > 0
            path += '../' 
            i-- 
            
        return path    

    fs.readdir dir, (err, files) ->
        for filename in files
          do (filename) ->
            path = dir + '/' + filename
            fs.stat path, (err, stats) ->
                if !err && stats.isFile()
                    fs.readFile path, (err, contents) ->
                        console.log "compiling file " + path.replace dataPath, ''
                        compile path, contents.toString(), basepath depth

                if !err && stats.isDirectory()
                    newdir = path.replace dataPath, outPath
                    fs.mkdir newdir , "777", (err) ->
                        parseDir (fs.realpathSync path), depth + 1

# copies the assets into the output folder
copyAssets = () ->
    console.log "copying assets"
    spawn = require('child_process').spawn
    cp  = spawn 'cp', ['-R', assetPath, outPath]
    cp.stdin.end()    

# checks a directory 
checkDir = (path, message, callback) ->
    fs.stat path, (err, stats) ->
        if !err && stats.isDirectory()
            callback stats
            return

        console.log message
        null    

# checks a file
checkFile = (path, message, callback) ->
    fs.stat path, (err, stats) ->
        if !err && stats.isFile()
            callback stats
            return

        console.log message
        null    

# process a data directory
process = (dir) ->    
    checkDir dir, "not a valid directory", (stats) ->
    
        sitePath = rdir =  fs.realpathSync dir
        configPath = rdir + '/config.coffee'
        
        addHelpers()
        
        checkFile configPath, "not a valid config file", (stats) ->

            # parse config file
            c = fs.readFileSync configPath
            vm.runInNewContext c.toString(), config, '.'

            templatePath = rdir + '/' + config.templates
            dataPath = rdir + '/' + config.data
            assetPath = rdir + '/' + config.assets
            outPath = rdir + '/' + config.output

            checkDir templatePath, "not a valid template directory", (stats) ->
                templatePath = fs.realpathSync templatePath

                checkDir dataPath, "not a valid data directory", (stats) ->
                    dataPath = fs.realpathSync dataPath

                    checkDir assetPath, "not a valid asset directory", (stats) ->

                        # check for output dir, create if neccesary
                        stats = fs.stat outPath, (err, stats) ->
                            if err
                                fs.mkdir outPath, '777', () ->
                                    startParsing()
                            else
                                startParsing()


        startParsing = () ->
            copyAssets()
            outPath = fs.realpathSync outPath
            parseDir fs.realpathSync dataPath


# check if argv is ok
args = require("argsparser").parse()

if !args["-d"]
    console.log "Usage: genstatic -d ./site"
    return

# start to process the directory
process args["-d"] 