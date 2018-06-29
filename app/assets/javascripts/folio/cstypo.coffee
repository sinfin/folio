$.fn.cstypo = ->
  regexp = /([szkvaiou%])/i
  @each ->
    $this = $(this)
    words = $this.html().split(' ')
    replaced = jQuery.map words, (word) ->
      if word.length is 1 and word.match(regexp)
        word.replace regexp, '$1&nbsp;'
      else
        word + ' '
    $this.html replaced.join('')

if $('html').prop('lang') is 'cs'
  $(document).on 'turbolinks:load', -> $('p').cstypo()
