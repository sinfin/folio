$ ->
  $wrap = $('.folio-console-menu-items-structure--root')
  return if $wrap.length isnt 1

  $wrap.nestedSortable
    items: '.nested-fields'
    handle: '.folio-console-menu-items-structure__handle'
    toleranceElement: '.nested-fields-inner'
    isTree: true
    forcePlaceholderSize: true
    helper: 'clone'
    opacity: 0.6
    maxLevels: $wrap.data('max-nesting-depth')

    update: ->
      window.FolioConsole.clearFlashes()
      output = $wrap.nestedSortable 'toArray'

      $.ajax
        method: 'POST'
        url: $wrap.data('update-url')
        data:
          id: $wrap.data('id')
          sortable: output
        success: ->
          window.FolioConsole.flash($wrap.data('success'))
        error: (res) ->
          message = $wrap.data('error').replace('MESSAGE', res.responseText)
          window.FolioConsole.flash(message, 'error')
