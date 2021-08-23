window.dummyBindClipboardsIn = ($wrap) ->
  $wrap.find('.d-ui-clipboard').each ->
    clipboard = new ClipboardJS(this)

    clipboard.on 'success', (e) ->
      $trigger = $(e.trigger)
      $trigger.addClass('d-ui-clipboard--copied')
      setTimeout (-> $trigger.removeClass('d-ui-clipboard--copied')), 1000

    $(this).data('clipboard', clipboard)

window.dummyUnbindClipboardsIn = ($wrap) ->
  $wrap.find('.d-ui-clipboard').each ->
    $this = $(this)
    clipboard = $this.data('clipboard')
    clipboard.destroy() if clipboard
    $this.data('clipboard', null)

$(document)
  .on 'turbolinks:load', ->
    window.dummyBindClipboardsIn($(document.body))

  .on 'turbolinks:before-render', ->
    window.dummyUnbindClipboardsIn($(document.body))
