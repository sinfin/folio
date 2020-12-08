$ ->
  if $('.f-c-clipboard-copy').length
    clipboard = new ClipboardJS('.f-c-clipboard-copy')

    clipboard.on 'success', (e) ->
      $trigger = $(e.trigger)
      $trigger.addClass('f-c-clipboard-copy--copied')
      setTimeout (-> $trigger.removeClass('f-c-clipboard-copy--copied')), 1000
