$(document).on 'cocoon:after-insert', (e, insertedItem) ->
  $(insertedItem).find('input[type="file"]').click()
