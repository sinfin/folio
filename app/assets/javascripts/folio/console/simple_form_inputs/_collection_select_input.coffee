SELECTOR = '.f-c-collection-remote-select-input'

window.folioConsoleBindCollectionSelectInput = ($elements) ->
  $elements.each ->
    $select = $(this)
    $select
      .select2
        width: "100%"
        language: document.documentElement.lang
        allowClear: true
        placeholder:
          id: ""
          text: $select.data("placeholder")
        ajax:
          url: $select.data("url")
          dataType: "JSON"
          minimumInputLength: 0
          cache: false
          data: (params) -> { q: params.term }

window.folioConsoleUnbindCollectionSelectInput = ($elements) ->
  $elements.each -> @select?.destroy()

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
