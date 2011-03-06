# Genstatic - A very simple static site generator

Work in progress.
Based on coffeescript and eco
You can define templates, partials and data files.

## Install

Clone the git, cd into dir and do "npm install"

## Run

Then you can run "genstatic -d ./example" to generate an example website in example/www.

## Variables inside the page

By default every page will have the following values set:

template (defaults to "index")
filename
basedir

Other variables can be set inside the file itself, by declaring them on top:

    ---
    title = "Foo page"
    ---

Site wide variables can be set in config.coffee

## Settings 

These default to:

    extension : '.html'
    templates : './templates'
    assets : './assets'
    data : './data'
    output : './www'

These values can be overwritten in config.coffee

