//= require popper.min
//= require folio/input/_framework
//= require tempus-dominus
//= require tempus-dominus-customDateFormat
//= require folio/input/date_time/tempus-dominus_clear_plugin

if (!window.Popper || !window.Popper.createPopper) {
  throw new Error('Missing window.Popper.createPopper! Folio DateTime input cannot work without it.')
}

window.tempusDominus.extend(window.tempusDominus.plugins.customDateFormat)

window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.DateTime = {}

window.Folio.Input.DateTime.SELECTOR = '.f-input--date'

window.Folio.Input.DateTime.DATE_TIME_CONFIG = {
  display: {
    sideBySide: true,
    icons: {
      type: 'icons',
      time: 'fa fa-clock f-input__ico f-input__ico--time',
      date: 'fa fa-calendar f-input__ico f-input__ico--date',
      up: 'fa fa-chevron-up f-input__ico f-input__ico--up',
      down: 'fa fa-chevron-down f-input__ico f-input__ico--down',
      previous: 'fa fa-chevron-left f-input__ico f-input__ico--previous',
      next: 'fa fa-chevron-right f-input__ico f-input__ico--next',
      today: 'fa fa-calendar-star f-input__ico f-input__ico--today',
      clear: 'fa fa-trash-alt f-input__ico f-input__ico--clear',
      close: 'fa fa-times f-input__ico f-input__ico--close'
    },
    theme: 'light'
  },
  localization: {
    locale: document.documentElement.lang,
    format: 'dd. MM. yyyy HH:mm'
  },
  keepInvalid: false,
  useCurrent: false,
  allowInputToggle: true
}

window.Folio.Input.DateTime.DATE_CONFIG = {
  ...window.Folio.Input.DateTime.DATE_TIME_CONFIG,
  localization: {
    ...window.Folio.Input.DateTime.DATE_TIME_CONFIG.localization,
    format: 'dd. MM. yyyy'
  }
}

window.Folio.Input.DateTime.i18n = window.Folio.Input.DateTime.i18n || {}

if (!window.Folio.Input.DateTime.i18n.clearDate) {
  if (window.FolioConsole && window.FolioConsole.translations) {
    window.Folio.Input.DateTime.i18n.clearDate = window.FolioConsole.translations.clearDate
  } else {
    if (document.documentElement.lang === 'cs') {
      window.Folio.Input.DateTime.i18n.clearDate = 'Vymazat datum'
    } else {
      window.Folio.Input.DateTime.i18n.clearDate = 'Clear date'
    }
  }
}

window.Folio.Input.DateTime.bind = (input, opts = {}) => {
  let fullOpts

  if (input.classList.contains('f-input--date-time')) {
    fullOpts = { ...window.Folio.Input.DateTime.DATE_TIME_CONFIG, ...opts }
  } else {
    fullOpts = { ...window.Folio.Input.DateTime.DATE_CONFIG, ...opts }
  }

  input.folioInputTempusDominus = new window.tempusDominus.TempusDominus(input, fullOpts)
}

window.Folio.Input.DateTime.unbind = (input) => {
  if (input.folioInputTempusDominus) {
    input.folioInputTempusDominus.dispose()
    input.folioInputTempusDominus = null
  }
}

window.Folio.Input.framework(window.Folio.Input.DateTime)
