(function() {
  var args, assetPath, checkDir, checkFile, compile, config, copyAssets, dataPath, eco, fs, helpers, outPath, parseDir, process, templatePath, _;
  _ = require("underscore");
  fs = require("fs");
  args = require("argsparser").parse();
  eco = require("eco");
  assetPath = outPath = dataPath = templatePath = null;
  config = {
    extension: '.html',
    templates: './templates',
    assets: './assets',
    data: './data',
    output: './www'
  };
  helpers = {
    partial: function(str) {
      var pcontent;
      pcontent = fs.readFileSync(templatePath + '/' + str + config.extension);
      return eco.render(pcontent.toString(), this);
    },
    highlight: function(str, check) {
      if (str === check) {
        return ' class="hi"';
      }
    }
  };
  compile = function(filename, content, basedir) {
    var env, fconfig, fname, matches, reg, template;
    fname = filename.replace(dataPath, '');
    reg = /config: (\{[\w\d\s\r\n\_\-\\/,:\’ '"\.]*\n\})/gim;
    matches = reg.exec(content);
    fconfig = {
      template: "index"
    };
    try {
      if (matches) {
        content = content.replace(matches[0], '');
        fconfig = _.extend(fconfig, JSON.parse(matches[1]));
      }
    } catch (e) {
      console.log("Not a valid file");
    }
    null;
    env = {
      filename: fname,
      basedir: basedir
    };
    template = templatePath + '/' + fconfig.template + config.extension;
    return fs.readFile(template, function(err, tcontent) {
      var output;
      content = eco.render(content, _.extend({}, config, fconfig, helpers, env));
      output = eco.render(tcontent.toString(), _.extend({}, config, fconfig, helpers, env, {
        content: content
      }));
      return fs.writeFile(outPath + fname, output, 'utf-8', function(err) {
        if (err) {
          return console.log(err);
        }
      });
    });
  };
  parseDir = function(dir, depth) {
    var basepath;
    depth != null ? depth : depth = 0;
    console.log(dir, depth);
    basepath = function(i) {
      var path;
      path = '';
      while (i > 0) {
        path += '../';
        i--;
      }
      return path;
    };
    return fs.readdir(dir, function(err, files) {
      var filename, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = files.length; _i < _len; _i++) {
        filename = files[_i];
        _results.push((function(filename) {
          var path;
          path = dir + '/' + filename;
          return fs.stat(path, function(err, stats) {
            var newdir;
            if (!err && stats.isFile()) {
              fs.readFile(path, function(err, contents) {
                console.log("compiling file " + path.replace(dataPath, ''));
                return compile(path, contents.toString(), basepath(depth));
              });
            }
            if (!err && stats.isDirectory()) {
              newdir = path.replace(dataPath, outPath);
              return fs.mkdir(newdir, "777", function(err) {
                return parseDir(fs.realpathSync(path), depth + 1);
              });
            }
          });
        })(filename));
      }
      return _results;
    });
  };
  copyAssets = function() {
    var cp, spawn;
    spawn = require('child_process').spawn;
    cp = spawn('cp', ['-R', assetPath, outPath]);
    console.log('Spawned child pid: ' + cp.pid);
    return cp.stdin.end();
  };
  checkDir = function(path, message, callback) {
    return fs.stat(path, function(err, stats) {
      if (!err && stats.isDirectory()) {
        callback(stats);
        return;
      }
      console.log(message);
      return null;
    });
  };
  checkFile = function(path, message, callback) {
    return fs.stat(path, function(err, stats) {
      if (!err && stats.isFile()) {
        callback(stats);
        return;
      }
      console.log(message);
      return null;
    });
  };
  process = function(dir) {
    return checkDir(dir, "not a valid directory", function(stats) {
      var configPath, rdir, startParsing;
      rdir = fs.realpathSync(dir);
      configPath = rdir + '/config.json';
      checkFile(configPath, "not a valid config file", function(stats) {
        var confOverride;
        confOverride = JSON.parse(fs.readFileSync(configPath).toString());
        config = _.extend(config, confOverride);
        templatePath = rdir + '/' + config.templates;
        dataPath = rdir + '/' + config.data;
        assetPath = rdir + '/' + config.assets;
        outPath = rdir + '/' + config.output;
        return checkDir(templatePath, "not a valid template directory", function(stats) {
          templatePath = fs.realpathSync(templatePath);
          return checkDir(dataPath, "not a valid data directory", function(stats) {
            dataPath = fs.realpathSync(dataPath);
            return checkDir(assetPath, "not a valid asset directory", function(stats) {
              return stats = fs.stat(outPath, function(err, stats) {
                if (err) {
                  return fs.mkdir(outPath, '777', function() {
                    return startParsing();
                  });
                } else {
                  return startParsing();
                }
              });
            });
          });
        });
      });
      return startParsing = function() {
        outPath = fs.realpathSync(outPath);
        parseDir(fs.realpathSync(dataPath));
        return copyAssets();
      };
    });
  };
  if (!args["-d"]) {
    console.log("Usage: genstatic -d ./site");
    return;
  }
  process(args["-d"]);
}).call(this);
