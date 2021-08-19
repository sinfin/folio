window.bindFolioConsoleClipboardCopyIn = ($wrap)->
  window.bindFolioConsoleClipboardCopy $wrap.find('.f-c-clipboard-copy')

window.bindFolioConsoleClipboardCopy = ($elements)->
  $elements.each ->
    clipboard = new ClipboardJS(this)

    clipboard.on 'success', (e) ->
      $trigger = $(e.trigger)
      $trigger.addClass('f-c-clipboard-copy--copied')
      setTimeout (-> $trigger.removeClass('f-c-clipboard-copy--copied')), 1000

    $(this).data('clipboard', clipboard)

window.unbindFolioConsoleClipboardCopy = ($elements)->
  $elements.each ->
    $this = $(this)
    clipboard = $this.data('clipboard')
    if clipboard
      clipboard.destroy()
      $this.data('clipboard', null)

$ ->
  if $('.f-c-clipboard-copy').length
    window.bindFolioConsoleClipboardCopy($('.f-c-clipboard-copy'))
