AUTOSIZE_SELECTOR = '.f-c-text-input--autosize'

bindAutosize = ($elements) ->
  autosize($elements)

unbindAutosize = ($elements) ->
  $elements.trigger('autosize.destroy')

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
