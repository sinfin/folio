REDACTOR_SELECTOR = '.folio-console-redactor-input'

bindRedactor = ($elements) ->
  $elements.each ->
    advanced = @classList.contains('folio-console-redactor-input--advanced')
    window.folioConsoleInitRedactor(this, advanced: advanced)

unbindRedactor = ($elements) ->
  $elements.each -> window.folioConsoleDestroyRedactor(this)

$document = $(document)

$document.on 'cocoon:after-insert', (e, insertedItem) ->
  bindRedactor(insertedItem.find(REDACTOR_SELECTOR))

$document.on 'cocoon:before-remove', (e, item) ->
  unbindRedactor(item.find(REDACTOR_SELECTOR))

if Turbolinks?
  $(document)
    .on 'turbolinks:load', ->
      bindRedactor($(REDACTOR_SELECTOR))

    .on 'turbolinks:before-cache', ->
      unbindRedactor($(REDACTOR_SELECTOR))

else
  $document.on 'ready', ->
    bindRedactor($(REDACTOR_SELECTOR))
