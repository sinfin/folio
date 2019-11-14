COLOR_INPUT_SELECTOR = '.folio-console-color-input'

CONFIG =
  allowEmpty: true
  showAlpha: true
  showButtons: false

window.folioConsoleInitColorPicker = (el, opts) ->
  $(el).spectrum($.extend({}, CONFIG, opts))

window.folioConsoleUnbindColorPicker = (el) ->
  $(el).spectrum('destroy')

bindColorPicker = ($elements) ->
  $elements.each ->
    $this = $(this)
    return if $this.hasClass('f-c-js-manual')
    window.folioConsoleInitColorPicker(this)

unbindColorPicker = ($elements) ->
  $elements.each -> window.folioConsoleUnbindColorPicker(this)

$(document)
  .on 'cocoon:after-insert', (e, insertedItem) ->
    bindColorPicker(insertedItem.find(COLOR_INPUT_SELECTOR))

  .on 'cocoon:before-remove', (e, item) ->
    unbindColorPicker(item.find(COLOR_INPUT_SELECTOR))

if Turbolinks?
  $(document)
    .on 'turbolinks:load', ->
      bindColorPicker($(COLOR_INPUT_SELECTOR))

    .on 'turbolinks:before-cache', ->
      unbindColorPicker($(COLOR_INPUT_SELECTOR))

else
  $ -> bindColorPicker($(COLOR_INPUT_SELECTOR))
