SELECTOR = '.f-c-collection-remote-select-input'

window.folioConsoleBindCollectionSelectInput = ($elements) ->
  $elements.each ->
    $selectize = $(this)
    $selectize
      .removeClass('form-control')
      .selectize
        preload: 'focus'
        load: (q, callback) ->
          $.ajax
            url: $selectize.data('autocomplete-url')
            method: 'GET'
            data:
              q: q
            error: ->
              callback()
            success: (res) ->
              callback(res.data)

window.folioConsoleUnbindCollectionSelectInput = ($elements) ->
  $elements.each -> @selectize?.destroy()

$(document)
  .on 'cocoon:after-insert', (e, insertedItem) ->
    window.folioConsoleBindCollectionSelectInput(insertedItem.find(SELECTOR))

  .on 'cocoon:before-remove', (e, item) ->
    window.folioConsoleUnbindCollectionSelectInput(item.find(SELECTOR))

if Turbolinks?
  $(document)
    .on 'turbolinks:load', ->
      window.folioConsoleBindCollectionSelectInput($(SELECTOR))

    .on 'turbolinks:before-cache', ->
      window.folioConsoleUnbindCollectionSelectInput($(SELECTOR))

else
  $ ->
    window.folioConsoleBindCollectionSelectInput($(SELECTOR))
