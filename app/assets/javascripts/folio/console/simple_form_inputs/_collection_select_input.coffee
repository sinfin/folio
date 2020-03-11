SELECTOR = '.f-c-collection-remote-select-input'

bindInputs = ($elements) ->
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

unbindInputs = ($elements) ->
  $elements.each -> @selectize?.destroy()

$(document)
  .on 'cocoon:after-insert', (e, insertedItem) ->
    bindInputs(insertedItem.find(SELECTOR))

  .on 'cocoon:before-remove', (e, item) ->
    unbindInputs(item.find(SELECTOR))

if Turbolinks?
  $(document)
    .on 'turbolinks:load', ->
      bindInputs($(SELECTOR))

    .on 'turbolinks:before-cache', ->
      unbindInputs($(SELECTOR))

else
  $ ->
    bindInputs($(SELECTOR))
