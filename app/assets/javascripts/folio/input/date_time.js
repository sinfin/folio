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

window.Folio.Input.DateTime.changedIconsToSvg = false

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
    format: 'dd. MM. yyyy, HH:mm',
    hourCycle: 'h23'
  },
  keepInvalid: false,
  useCurrent: false,
  allowInputToggle: true
}

window.Folio.Input.DateTime.DATE_CONFIG = {
  ...window.Folio.Input.DateTime.DATE_TIME_CONFIG,
  display: {
    ...window.Folio.Input.DateTime.DATE_TIME_CONFIG.display,
    sideBySide: false,
    components: {
      ...window.Folio.Input.DateTime.DATE_TIME_CONFIG.display.components,
      clock: false,
      hours: false,
      minutes: false,
      seconds: false
    }
  },
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

window.Folio.Input.DateTime.updateIconsIfNeeded = (input) => {
  if (!window.Folio.Input.DateTime.changedIconsToSvg && input && input.dataset.spriteUrl) {
    const newIcons = {}

    Object.keys(window.Folio.Input.DateTime.DATE_TIME_CONFIG.display.icons).forEach((key) => {
      newIcons[key] = key === 'type' ? 'sprites' : `${input.dataset.spriteUrl}#${key}`
    })

    window.Folio.Input.DateTime.DATE_TIME_CONFIG.display.icons = newIcons
    window.Folio.Input.DateTime.DATE_CONFIG.display.icons = newIcons

    window.Folio.Input.DateTime.changedIconsToSvg = true
  }
}

window.Folio.Input.DateTime.makeOnShow = (input) => {
  if (input.dataset.default) {
    return () => {
      if (input.folioInputTempusDominus && !input.folioInputDidSetDefault && input.value === "") {
        input.folioInputDidSetDefault = true
        input.folioInputTempusDominus.dates.setFromInput(input.dataset.default)
      }
    }
  }
}


window.Folio.Input.DateTime.makeOnChange = (input) => (e) => {
  if (input.value === '' || (e.date && !e.oldDate) || (e.date && e.oldDate && Math.abs(e.date - e.oldDate) > 60 * 60 * 1000 + 1)) {
    input.folioInputTempusDominus.hide()
  }

  if (e.date === e.oldDate) return

  input.dispatchEvent(new window.Event('input', { bubbles: true }))
  input.dispatchEvent(new window.Event('change', { bubbles: true }))
}

window.Folio.Input.DateTime.bind = (input, opts = {}) => {
  window.Folio.Input.DateTime.unbind(input)
  window.Folio.Input.DateTime.updateIconsIfNeeded(input)

  let fullOpts

  if (input.classList.contains('f-input--date-time')) {
    fullOpts = { ...window.Folio.Input.DateTime.DATE_TIME_CONFIG, ...opts }
  } else {
    fullOpts = { ...window.Folio.Input.DateTime.DATE_CONFIG, ...opts }
  }

  input.folioInputTempusDominus = new window.tempusDominus.TempusDominus(input, fullOpts)
  input.folioInputTempusDominusChangeSubscription = input.folioInputTempusDominus.subscribe(window.tempusDominus.Namespace.events.change, window.Folio.Input.DateTime.makeOnChange(input))

  const onShow = window.Folio.Input.DateTime.makeOnShow(input)

  if (onShow) {
    input.folioInputTempusDominusShowSubscription = input.folioInputTempusDominus.subscribe(window.tempusDominus.Namespace.events.show, onShow)
  }
}

window.Folio.Input.DateTime.unbind = (input) => {
  if (input.folioInputTempusDominusChangeSubscription) {
    input.folioInputTempusDominusChangeSubscription.unsubscribe()
    input.folioInputTempusDominusChangeSubscription = null
  }

  if (input.folioInputTempusDominusShowSubscription) {
    input.folioInputTempusDominusShowSubscription.unsubscribe()
    input.folioInputTempusDominusShowSubscription = null
  }

  if (input.folioInputTempusDominus) {
    input.folioInputTempusDominus.dispose()
    input.folioInputTempusDominus = null
  }
}

window.Folio.Input.framework(window.Folio.Input.DateTime)
