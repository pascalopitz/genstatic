# just some example helpers

posts = 0

highlight = (str, check) ->
    if(str == check)
        ' class="hi"'
            
getposts = () ->
    return posts++
            