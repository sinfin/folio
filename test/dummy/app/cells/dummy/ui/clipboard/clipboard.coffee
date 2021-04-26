clipboards = []

$(document)
  .on 'turbolinks:load', ->
    $('.d-ui-clipboard').each ->
      clipboard = new ClipboardJS(this)

      clipboard.on 'success', (e) ->
        $trigger = $(e.trigger)
        $trigger.addClass('d-ui-clipboard--copied')
        setTimeout (-> $trigger.removeClass('d-ui-clipboard--copied')), 1000

      clipboards.push(clipboard)

  .on 'turbolinks:before-render', ->
    clipboards.forEach (clipboard) -> clipboard.destroy()
    clipboards = []
