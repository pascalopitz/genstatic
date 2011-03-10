#includes
coffee = require "coffee-script"
path = require "path"
vm = require "vm"
_ = require "underscore"
fs = require "fs"
eco = require "eco"

extension = sitePath = assetPath = outPath = dataPath = templatePath = null

# defaul config
config =
    extension : '.html'
    templates : './templates'
    assets : './assets'
    data : './data'
    output : './www'

# defaul helpers
helpers = 
    partial : (str, vars) ->
        pcontent = fs.readFileSync templatePath + '/' + str + extension
        eco.render pcontent.toString(), (_.extend this, vars || {})

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

    template = templatePath + '/' + fconfig.template + extension

    # read template file, render template and content
    fs.readFile template, (err, tcontent) ->
        locals = _.extend {}, config, fconfig, helpers, env
        locals.content = eco.render content, locals
        output = eco.render tcontent.toString(), locals

        fs.writeFile (outPath + fname), output, 'utf-8', (err) ->
            if(err)
                console.log err
        
# parses directories recusively
parseDir = (dir, depth) ->
    depth ?= 0
    console.log "parsing " + dir

    basepath = (i) ->
        basepath = ''
        while i > 0
            basepath += '../' 
            i-- 
            
        return basepath
        
    handleDir = (filename) ->
        filepath = path.normalize dir + '/' + filename
        fs.stat filepath, (err, stats) -> 
            if !err && stats.isFile()
                fs.readFile filepath, (err, contents) ->
                    console.log "compiling file " + filepath.replace dataPath, ''
                    compile filepath, contents.toString(), basepath depth
            
            if !err && stats.isDirectory()
                newdir = filepath.replace dataPath, outPath
                fs.mkdir newdir , "777", (err) ->
                    parseDir (path.normalize filepath), depth + 1
            

    fs.readdir dir, (err, files) ->
        if err then console.log err.toString()
        if files && files.length
            for filename in files
                do (filename) ->
                    handleDir filename

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
    extension = config.extension

    checkDir dir, "not a valid directory", (stats) ->
    
        sitePath = rdir =  path.normalize dir
        configPath = rdir + '/config.coffee'
        
        addHelpers()
        
        checkFile configPath, "not a valid config file", (stats) ->

            # parse config file
            c = fs.readFileSync configPath
            js = coffee.compile c.toString(), bare: 1
            vm.runInNewContext js, config, '.'

            templatePath = rdir + '/' + config.templates
            dataPath = rdir + '/' + config.data
            assetPath = rdir + '/' + config.assets
            outPath = rdir + '/' + config.output

            checkDir templatePath, "not a valid template directory", (stats) ->
                templatePath = path.normalize templatePath

                checkDir dataPath, "not a valid data directory", (stats) ->
                    dataPath = path.normalize dataPath

                    checkDir assetPath, "not a valid asset directory", (stats) ->

                        # check for output dir, create if neccesary
                        stats = fs.stat outPath, (err, stats) ->
                            if err
                                fs.mkdir outPath, '777', () ->
                                    startParsing()
                            else
                                startParsing()


        startParsing = () ->
            # clean the config object
            config = {}
            copyAssets()
            outPath = path.normalize  outPath
            parseDir path.normalize  dataPath

create = (dir) ->
    console.log "create example structure"
    spawn = require('child_process').spawn
    cp  = spawn 'cp', ['-R', __dirname + '/../example', path.normalize dir]
    
    failed = false
    
    cp.stderr.on 'data', (data) ->
        if !failed
            console.log ""
            console.log "ERROR:"
            console.log "creating example structure failed."
            console.log "Maybe the containing directory doesn\'t exists?"
            failed = true
            
        cp.stderr.end()    
        
    cp.stdin.end()    

# check if argv is ok
args = require("argsparser").parse()

if !args["process"] && !args["create"]
    console.log ""
    console.log "To create a site:"
    console.log "   genstatic create /path/to/site"
    console.log ""
    console.log "To process a site:"
    console.log "   genstatic process /path/to/site"
    console.log ""
    return

# create an example folder
if args["create"]
    create args["create"]
        
# start to process the directory
if args["process"]
    process args["process"] 