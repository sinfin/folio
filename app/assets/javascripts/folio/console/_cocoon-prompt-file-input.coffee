$(document).on 'cocoon:after-insert', (e, insertedItem) ->
  $insertedItem = $(insertedItem)
  if $insertedItem.data('prompt-file-input') != false
    $insertedItem.find('input[type="file"]').click()
