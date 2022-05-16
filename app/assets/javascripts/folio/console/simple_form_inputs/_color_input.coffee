hasColorInputSupport = ->
  input = document.createElement('input')
  input.type = 'color'
  input.value = '!'
  result = input.type is 'color' and input.value isnt '!'
  input = null
  return result

unless hasColorInputSupport()
  COLOR_INPUT_SELECTOR = '.f-c-color-input'

  CONFIG =
    allowEmpty: true
    showAlpha: true
    showButtons: false
    preferredFormat: 'hex'

  supports = undefined

  testSupport = ->

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
