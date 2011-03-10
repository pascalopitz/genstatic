# Genstatic - A very simple static site generator

Very early days.
Based on coffeescript and eco
You can define templates, partials and data files.

## Install

    npm install genstatic

## Run

Create an example directory via

    genstatic example ./example


Then you can run 
    
    genstatic process ./example
    
to generate the website in example/www.

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

## Helpers

By default available is the partial helper
    
    <%- @partial 'mytemplatename', { myvar : 'myvalue' } %>
    
Additional helpers can be defined in the file called helpers.coffee    