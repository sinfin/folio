//= require folio/input/_framework

AUTOSIZE_SELECTOR = '.f-input--autosize'

bindAutosize = ($elements) ->

unbindAutosize = ($elements) ->

$(document)
  .on 'cocoon:after-insert', (e, insertedItem) ->
    bindAutosize(insertedItem.find(AUTOSIZE_SELECTOR))

  .on 'cocoon:before-remove', (e, item) ->
    unbindAutosize(item.find(AUTOSIZE_SELECTOR))

if Turbolinks?
  $(document)
    .on 'turbolinks:load', ->
      bindAutosize($(AUTOSIZE_SELECTOR))

    .on 'turbolinks:before-cache', ->
      unbindAutosize($(AUTOSIZE_SELECTOR))

else
  $ ->
    bindAutosize($(AUTOSIZE_SELECTOR))

window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.Autosize = {}

window.Folio.Input.Autosize.SELECTOR = '.f-input--autosize'

window.Folio.Input.Autosize.bindAll = ($wrap) => {
  $wrap = $wrap || $(document.body)

  $wrap.find(window.Folio.Input.Autosize.SELECTOR).each((i, input) => {
    autosize($(input))
  })
}

window.Folio.Input.Autosize.unbindAll = ($wrap) => {
  $wrap = $wrap || $(document.body)

  $wrap.find(window.Folio.Input.Autosize.SELECTOR).trigger('autosize.destroy')
}

window.Folio.Input.Framework.bindInputEvents(window.Folio.Input.Autosize.bindAll,
                                             window.Folio.Input.Autosize.unbindAll)
