INPUT_SELECTOR = '.position, .folio-console-nested-model-position-input'

$(document).on 'cocoon:after-insert', (e, insertedItem) ->
  $item = $(insertedItem)
  $input = $(insertedItem).find(INPUT_SELECTOR)

  return unless $input.length

  pos =  $item.prevAll('.nested-fields:first')
              .find(INPUT_SELECTOR)
              .val()

  $input.val(parseInt(pos) + 1)
