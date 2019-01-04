CONFIG =
  format: 'dd/mm/yyyy',
  language: 'cs'

DATE_INPUT_SELECTOR = '.folio-console-date-picker'

$ ->
  $(DATE_INPUT_SELECTOR).datepicker CONFIG
  
$(document).on 'cocoon:after-insert', (e, insertedItem) ->
  insertedItem.find(DATE_INPUT_SELECTOR).datepicker CONFIG
