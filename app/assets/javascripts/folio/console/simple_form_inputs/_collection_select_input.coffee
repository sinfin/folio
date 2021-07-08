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
          data: (params) ->
            data = { q: params.term, page: params.page || 1 }

            $('.f-c-js-atoms-placement-setting').each ->
              $this = $(this)
              value = $this.val()
              data["by_atom_setting_#{$this.data('atom-setting')}"] = value

            return data

          processResults: (data, params) ->
            return {
              results: data.results
              pagination:
                more: data.meta and data.meta.pages > data.meta.page
            }

        templateSelection: (data, container) ->
          $el = $(data.element)
          Object.keys(data).forEach (key) ->
            if key.indexOf('data-') is 0
              $el.attr(key, data[key])
          return data.text

window.folioConsoleUnbindCollectionSelectInput = ($elements) ->
  $elements.each -> $(this).select2('destroy')

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
