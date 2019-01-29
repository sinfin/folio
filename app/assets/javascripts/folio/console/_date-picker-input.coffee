CONFIG =
  language: document.documentElement.lang
  sideBySide: true

DATE_CONFIG = $.extend {}, CONFIG, format: 'LT'

DATE_INPUT_SELECTOR = '.folio-console-date-picker'

bindDatePicker = ($elements) ->
  $elements.each ->
    $this = $(this)
    $this.attr('data-target', "##{@id}")
    if $this.hasClass('folio-console-date-picker--date')
      $this.datetimepicker(DATE_CONFIG)
    else
      $this.datetimepicker(CONFIG)

$ -> bindDatePicker($(DATE_INPUT_SELECTOR))

$(document).on 'cocoon:after-insert', (e, insertedItem) ->
  bindDatePicker(insertedItem.find(DATE_INPUT_SELECTOR))
