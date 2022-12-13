//= require folio/input/_framework
//= require moment/moment
//= require moment/locale/cs
//= require eonasdan-bootstrap-datetimepicker/build/js/bootstrap-datetimepicker.min

window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.DateTime = {}

if (window.FolioConsole && window.FolioConsole.translations) {
  window.Folio.Input.DateTime.i18n = {
    clearDate: window.FolioConsole.translations.clearDate
  }
} else {
  if (document.documentElement.lang === 'cs') {
    window.Folio.Input.DateTime.i18n = {
      clearDate: 'Vymazat datum'
    }
  } else {
    window.Folio.Input.DateTime.i18n = {
      clearDate: 'Clear date'
    }
  }
}

window.Folio.Input.DateTime.SELECTOR = '.f-input--date'

window.Folio.Input.DateTime.DATE_TIME_CONFIG = {
  locale: document.documentElement.lang,
  sideBySide: true,
  format: 'DD. MM. YYYY HH:mm',
  keepInvalid: false,
  useCurrent: false,
  widgetPositioning: {
    horizontal: 'auto',
    vertical: 'bottom'
  },
  icons: {
    time: 'fa fa-clock f-input__ico f-input__ico--time',
    date: 'fa fa-calendar f-input__ico f-input__ico--date',
    up: 'fa fa-chevron-up f-input__ico f-input__ico--up',
    down: 'fa fa-chevron-down f-input__ico f-input__ico--down',
    previous: 'fa fa-chevron-left f-input__ico f-input__ico--previous',
    next: 'fa fa-chevron-right f-input__ico f-input__ico--next',
    today: 'fa fa-calendar-star f-input__ico f-input__ico--today',
    clear: 'fa fa-trash f-input__ico f-input__ico--clear',
    close: 'fa fa-times f-input__ico f-input__ico--close'
  }
}

window.Folio.Input.DateTime.DATE_CONFIG = $.extend(
  {},
  window.Folio.Input.DateTime.DATE_TIME_CONFIG,
  { format: 'DD. MM. YYYY' }
)

window.Folio.Input.DateTime.onDatepickerShow = (e) => {
  const $input = $(e.currentTarget)
  const $picker = $input.siblings('.bootstrap-datetimepicker-widget')

  if ($picker.find('.bootstrap-datetimepicker-widget__reset-wrap').length === 0) {
    $picker.append(`
      <div class="bootstrap-datetimepicker-widget__reset-wrap">
        <span class="f-c-with-icon text-danger bootstrap-datetimepicker-widget__reset cursor-pointer">
          <span class="fa fa-trash-alt f-input__ico f-input__ico--trash-alt"></span> ${window.Folio.Input.DateTime.i18n.clearDate}
          </span>
      </div>
    `)
  }

  $(document).on('click.folioInputDateTime', (e) => {
    window.setTimeout(() => {
      const $target = $(e.target)

      if (!$target.hasClass('folio-console-date-picker') && $target.closest('.bootstrap-datetimepicker-widget').length === 0) {
        const picker = $picker.data('DateTimePicker')
        if (picker) picker.hide()
      }
    }, 0)
  })
}

window.Folio.Input.DateTime.onDatepickerHide = (e) => {
  $(document).off('click.folioInputDateTime')
}

window.Folio.Input.DateTime.onDatepickerChange = (e) => {
  const $input = $(e.currentTarget)

  if (e.date) {
    $input.data('date', window.moment(e.date).format())
  } else {
    $input.data('date', null)
  }

  $input
    .trigger('folioCustomChange')
    .closest('.f-c-simple-form-with-atoms__form, .f-c-dirty-simple-form')
    .trigger('change')
}

window.Folio.Input.DateTime.bind = (input, opts) => {
  const $input = $(input)
  let fullOpts

  if ($input.hasClass('f-input--date-time')) {
    fullOpts = $.extend({}, window.Folio.Input.DateTime.DATE_TIME_CONFIG, opts)
  } else {
    fullOpts = $.extend({}, window.Folio.Input.DateTime.DATE_CONFIG, opts)
  }

  if ($input.hasClass('f-input--date-on-top')) {
    fullOpts.widgetPositioning.vertical = 'top'
  }

  if ($input.data('date')) {
    $input.val(window.moment($input.data('date')).format(fullOpts.format))
  }

  $input.datetimepicker(fullOpts)

  $input
    .on('dp.change', window.Folio.Input.DateTime.onDatepickerChange)
    .on('dp.show', window.Folio.Input.DateTime.onDatepickerShow)
    .on('dp.hide', window.Folio.Input.DateTime.onDatepickerHide)
}

window.Folio.Input.DateTime.unbind = (input) => {
  $(input)
    .off('dp.change', window.Folio.Input.DateTime.onDatepickerChange)
    .off('dp.show', window.Folio.Input.DateTime.onDatepickerShow)
    .off('dp.hide', window.Folio.Input.DateTime.onDatepickerHide)
    .datetimepicker('destroy')
}

window.Folio.Input.framework(window.Folio.Input.DateTime)

$(document)
  .on('click', '.bootstrap-datetimepicker-widget__reset', (e) => {
    e.preventDefault()
    e.stopPropagation()
    const picker = $(e.currentTarget).closest('.form-group, .f-c-r-notes-fields-app-table-due-date').find('.form-control').data('DateTimePicker')
    picker.clear()
    picker.hide()
  })
