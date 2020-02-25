CONFIG =
  locale: document.documentElement.lang
  sideBySide: true
  format: 'DD. MM. YYYY HH:mm'
  keepInvalid: false
  icons:
    time: 'fa fa-clock',
    date: 'fa fa-calendar',
    up: 'fa fa-chevron-up',
    down: 'fa fa-chevron-down',
    previous: 'fa fa-chevron-left',
    next: 'fa fa-chevron-right',
    today: 'fa fa-calendar-star',
    clear: 'fa fa-trash',
    close: 'fa fa-times'

DATE_CONFIG = $.extend {}, CONFIG, format: 'DD. MM. YYYY'

DATE_INPUT_SELECTOR = '.folio-console-date-picker'

dpChange = (e) ->
  return unless e.date
  @dataset.date = e.date.format()

window.folioConsoleInitDatePicker = (el) ->
  $el = $(el)
  $el.val(moment($el.data('date')).format(DATE_CONFIG.format)) if $el.data('date')
  $el.datetimepicker(DATE_CONFIG)
  $el.on 'dp.change', dpChange

window.folioConsoleInitDateTimePicker = (el) ->
  $el = $(el)
  $el.val(moment($el.data('date')).format(CONFIG.format)) if $el.data('date')
  $el.datetimepicker(CONFIG)
  $el.on 'dp.change', dpChange

window.folioConsoleUnbindDatePicker = (el) ->
  $(el)
    .datetimepicker('destroy')
    .off 'dp.change'

bindDatePicker = ($elements) ->
  $elements.each ->
    $this = $(this)
    return if $this.hasClass('f-c-js-manual')

    if $this.hasClass('folio-console-date-picker--date')
      window.folioConsoleInitDatePicker(this)
      $this.datetimepicker(DATE_CONFIG)
    else
      window.folioConsoleInitDateTimePicker(this)

unbindDatePicker = ($elements) ->
  $elements.datetimepicker('destroy')

$(document)
  .on 'click', (e) ->
    $picker = $('.bootstrap-datetimepicker-widget')
    $target = $(e.target)
    if $picker.length and not $target.hasClass('folio-console-date-picker') and not $.contains($picker, $target)
      $(DATE_INPUT_SELECTOR).each ->
        picker = $(this).data('DateTimePicker')
        picker.hide() if picker

  .on 'cocoon:after-insert', (e, insertedItem) ->
    bindDatePicker(insertedItem.find(DATE_INPUT_SELECTOR))

  .on 'cocoon:before-remove', (e, item) ->
    unbindDatePicker(item.find(DATE_INPUT_SELECTOR))

if Turbolinks?
  $(document)
    .on 'turbolinks:load', ->
      bindDatePicker($(DATE_INPUT_SELECTOR))

    .on 'turbolinks:before-cache', ->
      unbindDatePicker($(DATE_INPUT_SELECTOR))

else
  $ -> bindDatePicker($(DATE_INPUT_SELECTOR))
