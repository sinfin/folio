$(document).on 'cocoon:after-insert', (e, insertedItem) ->
  $item = $(insertedItem)

  pos =  $item.prevAll('.nested-fields:first')
              .find('.position, .folio-console-nested-model-position-input')
              .val()

  $(insertedItem).find('.position').val(parseInt(pos) + 1)
