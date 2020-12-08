REDACTOR_SELECTOR = '.f-c-redactor-input'

bindRedactor = ($elements) ->
  $elements.each ->
    opts =
      advanced: @classList.contains('f-c-redactor-input--advanced')
      email: @classList.contains('f-c-redactor-input--email')

    additional = {}

    if @classList.contains('f-c-js-atoms-placement-perex')
      additional =
        callbacks:
          keyup: ->
            data =
              type: 'updatePerex'
              locale: null
              value: @source.getCode()

            $('.f-c-simple-form-with-atoms__iframe, .f-c-merges-form-row__atoms-iframe').each ->
              @contentWindow.postMessage(data, window.origin)

    window.folioConsoleInitRedactor(this, opts, additional)

unbindRedactor = ($elements) ->
  $elements.each -> window.folioConsoleDestroyRedactor(this)

$(document)
  .on 'cocoon:after-insert', (e, insertedItem) ->
    bindRedactor(insertedItem.find(REDACTOR_SELECTOR))

  .on 'cocoon:before-remove', (e, item) ->
    unbindRedactor(item.find(REDACTOR_SELECTOR))

if Turbolinks?
  $(document)
    .on 'turbolinks:load', ->
      bindRedactor($(REDACTOR_SELECTOR))

    .on 'turbolinks:before-cache', ->
      unbindRedactor($(REDACTOR_SELECTOR))

else
  $ ->
    bindRedactor($(REDACTOR_SELECTOR))
