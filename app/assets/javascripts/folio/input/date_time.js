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

window.Folio.Input.DateTime.changedIconsToSvg = false

window.Folio.Input.DateTime.DATE_TIME_CONFIG = {
  display: {
    sideBySide: true,
    icons: {
      type: 'icons',
      time: 'f-input__ico f-input__ico--time',
      date: 'f-input__ico f-input__ico--date',
      up: 'f-input__ico f-input__ico--up',
      down: 'f-input__ico f-input__ico--down',
      previous: 'f-input__ico f-input__ico--previous',
      next: 'f-input__ico f-input__ico--next',
      today: 'f-input__ico f-input__ico--today',
      clear: 'f-input__ico f-input__ico--clear',
      close: 'f-input__ico f-input__ico--close'
    },
    theme: 'light'
  },
  localization: {
    locale: document.documentElement.lang,
    format: 'd. M. yyyy, H:mm',
    hourCycle: 'h23',
    startOfTheWeek: 1
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
    format: 'd. M. yyyy'
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

window.Folio.Input.DateTime.updateIconsIfNeeded = (input, opts) => {
  if (!window.Folio.Input.DateTime.changedIconsToSvg && input && opts.spriteUrl) {
    const newIcons = {}

    Object.keys(window.Folio.Input.DateTime.DATE_TIME_CONFIG.display.icons).forEach((key) => {
      newIcons[key] = key === 'type' ? 'sprites' : `${opts.spriteUrl}#${key}`
    })

    window.Folio.Input.DateTime.DATE_TIME_CONFIG.display.icons = newIcons
    window.Folio.Input.DateTime.DATE_CONFIG.display.icons = newIcons

    window.Folio.Input.DateTime.changedIconsToSvg = true
  }
}

window.Folio.Input.DateTime.makeOnShow = (input) => {
  if (input.dataset.default) {
    return () => {
      if (input.folioInputTempusDominus && !input.folioInputDidSetDefault && input.value === '') {
        input.folioInputDidSetDefault = true
        input.folioInputTempusDominus.dates.setFromInput(input.dataset.default)
      }
    }
  }
}

// Widget actions that pick a date or remove it. They close the picker; time
// controls (arrows, hour and minute grids, AM/PM) keep it open, so the time can
// be set in several clicks even when the input was empty before the first one.
window.Folio.Input.DateTime.CLOSING_ACTIONS = ['selectDay', 'today', 'clear']

window.Folio.Input.DateTime.HOUR_MS = 60 * 60 * 1000

// Hides the picker unless the host asked Tempus Dominus to keep it on screen.
window.Folio.Input.DateTime.hidePicker = (input) => {
  const picker = input.folioInputTempusDominus
  if (!picker) return

  const display = picker.optionsStore.options.display
  if (display.keepOpen || display.inline) return

  picker.hide()
}

// Tempus Dominus change events do not say which control made the change.
// A capture listener on the widget remembers the clicked action before the
// Tempus Dominus handler on the control runs (its change or error event is
// synchronous); a bubble listener on the widget decides at the end of the same
// click and forgets the action, so it never outlives its click. A closing
// action closes the picker even without a change (the day that is already
// selected), but not when Tempus Dominus rejected the pick (min/max).
window.Folio.Input.DateTime.trackWidgetActions = (input) => {
  const picker = input.folioInputTempusDominus
  const widget = picker && picker.display.widget
  if (!widget || widget.folioInputDateTimeTracksActions) return

  widget.folioInputDateTimeTracksActions = true

  widget.addEventListener('click', (e) => {
    const actionElement = e.target.closest('[data-action]')
    const enabled = actionElement && widget.contains(actionElement) && !actionElement.classList.contains('disabled')
    widget.folioInputDateTimeAction = enabled ? actionElement.dataset.action : null
    input.folioInputDateTimeActionFailed = false
  }, true)

  widget.addEventListener('click', () => {
    const action = widget.folioInputDateTimeAction
    widget.folioInputDateTimeAction = null

    if (window.Folio.Input.DateTime.CLOSING_ACTIONS.includes(action) && !input.folioInputDateTimeActionFailed) {
      window.Folio.Input.DateTime.hidePicker(input)
    }
  })
}

// A change made by a widget control is decided by the click listener above.
// A change from outside the widget (typed value, default value, host code)
// closes the picker when the input is cleared, gets its first date or jumps by
// more than an hour, as before.
window.Folio.Input.DateTime.shouldHideOnChange = (input, e) => {
  const widget = input.folioInputTempusDominus.display.widget
  if (widget && widget.folioInputDateTimeAction) return false

  if (input.value === '') return true
  if (e.date && !e.oldDate) return true

  return !!(e.date && e.oldDate && Math.abs(e.date - e.oldDate) > window.Folio.Input.DateTime.HOUR_MS + 1)
}

window.Folio.Input.DateTime.makeOnChange = (input) => (e) => {
  if (window.Folio.Input.DateTime.shouldHideOnChange(input, e)) {
    window.Folio.Input.DateTime.hidePicker(input)
  }

  if (e.date === e.oldDate) return

  input.dispatchEvent(new window.Event('input', { bubbles: true }))
  input.dispatchEvent(new window.Event('change', { bubbles: true }))
}

window.Folio.Input.DateTime.bind = (input, opts = {}) => {
  window.Folio.Input.DateTime.unbind(input)
  window.Folio.Input.DateTime.updateIconsIfNeeded(input, opts)

  let fullOpts

  if (opts.type === 'date') {
    fullOpts = { ...window.Folio.Input.DateTime.DATE_CONFIG, ...opts.tempusDominusOptions }
  } else {
    fullOpts = { ...window.Folio.Input.DateTime.DATE_TIME_CONFIG, ...opts.tempusDominusOptions }
  }

  input.folioInputTempusDominus = new window.tempusDominus.TempusDominus(input, fullOpts)
  input.folioInputTempusDominusChangeSubscription = input.folioInputTempusDominus.subscribe(window.tempusDominus.Namespace.events.change, window.Folio.Input.DateTime.makeOnChange(input))
  input.folioInputTempusDominusErrorSubscription = input.folioInputTempusDominus.subscribe(window.tempusDominus.Namespace.events.error, () => {
    input.folioInputDateTimeActionFailed = true
  })

  const onShow = window.Folio.Input.DateTime.makeOnShow(input)

  input.folioInputTempusDominusShowSubscription = input.folioInputTempusDominus.subscribe(window.tempusDominus.Namespace.events.show, (e) => {
    window.Folio.Input.DateTime.trackWidgetActions(input)
    if (onShow) onShow(e)
  })

  // an inline picker is shown by the constructor, before the subscription above
  window.Folio.Input.DateTime.trackWidgetActions(input)
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

  if (input.folioInputTempusDominusErrorSubscription) {
    input.folioInputTempusDominusErrorSubscription.unsubscribe()
    input.folioInputTempusDominusErrorSubscription = null
  }

  if (input.folioInputTempusDominus) {
    input.folioInputTempusDominus.dispose()
    input.folioInputTempusDominus = null
  }
}

window.Folio.Stimulus.register('f-input-date-time', class extends window.Stimulus.Controller {
  static values = {
    max: { type: String, default: '' },
    min: { type: String, default: '' },
    type: { type: String, default: 'date' },
    calendarOnTop: { type: Boolean, default: false },
    spriteUrl: { type: String, default: '' }
  }

  connect () {
    const opts = {
      tempusDominusOptions: {},
      type: this.typeValue,
      calendarOnTop: this.calendarOnTopValue,
      spriteUrl: this.spriteUrlValue
    }

    this.element.autocomplete = 'off'
    this.element.dataset.toggle = 'datetimepicker'
    this.element.dataset.bsToggle = 'datetimepicker'

    if (this.minValue || this.maxValue) {
      opts.tempusDominusOptions.restrictions = {}

      if (this.minValue) opts.tempusDominusOptions.restrictions.minDate = this.minValue
      if (this.maxValue) opts.tempusDominusOptions.restrictions.maxDate = this.maxValue
    }

    if (opts.type === 'date' && !this.element.value) {
      // Without an initial value, Tempus Dominus seeds viewDate with the current
      // moment (incl. time-of-day). Clicking a day then compares that leftover
      // time-of-day against a midnight-based min/maxDate, so e.g. "today" can
      // fail to be selectable until some other date is picked first. Seed
      // viewDate at midnight so day clicks always compare cleanly.
      const todayAtMidnight = new Date()
      todayAtMidnight.setHours(0, 0, 0, 0)
      opts.tempusDominusOptions.viewDate = todayAtMidnight
    }

    window.Folio.Input.DateTime.bind(this.element, opts)
  }

  disconnect () {
    window.Folio.Input.DateTime.unbind(this.element)
  }
})
