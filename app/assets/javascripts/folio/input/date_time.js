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

window.Folio.Input.DateTime.dayValue = (dateTime) => {
  return `${dateTime.year}-${dateTime.monthFormatted}-${dateTime.dateFormatted}`
}

// A closing action that did not change the value either confirms the date that
// is already picked (close) or was rejected by Tempus Dominus, e.g. by min/max
// (keep the picker open).
window.Folio.Input.DateTime.confirmsPickedDate = (picker, action, target) => {
  if (action === 'clear') return true

  const lastPicked = picker.dates.lastPicked
  if (!lastPicked) return false

  if (action === 'today') {
    return lastPicked.isSame(new window.tempusDominus.DateTime(), window.tempusDominus.Unit.date)
  }

  return !!target && target.dataset.value === window.Folio.Input.DateTime.dayValue(lastPicked)
}

window.Folio.Input.DateTime.shouldHideAfterAction = (picker, action, changed, target) => {
  if (!window.Folio.Input.DateTime.CLOSING_ACTIONS.includes(action)) return false
  if (action === 'selectDay' && picker.optionsStore.options.multipleDates) return false
  if (changed) return true

  return window.Folio.Input.DateTime.confirmsPickedDate(picker, action, target)
}

// Tempus Dominus runs every widget action through `picker.actions.do`. Wrapping
// it gives the exact action and whether it changed the value: the change event
// is synchronous inside the call. The state lives in one object per input.
window.Folio.Input.DateTime.wrapActions = (input) => {
  const picker = input.folioInputTempusDominus
  const state = input.folioInputDateTimeState
  const originalDo = picker.actions.do

  picker.actions.do = function (e, action) {
    if (state.action) return originalDo.call(this, e, action)

    const target = e && e.currentTarget
    const name = action || (target && target.dataset ? target.dataset.action : null)

    state.action = name
    state.changed = false

    let result

    try {
      result = originalDo.call(this, e, action)
    } finally {
      state.action = null
    }

    if (result !== false && window.Folio.Input.DateTime.shouldHideAfterAction(picker, name, state.changed, target)) {
      window.Folio.Input.DateTime.hidePicker(input)
    }

    return result
  }

  state.restoreActions = () => { picker.actions.do = originalDo }
}

// Mousedown on the widget blurs the input, so a typed value is parsed before
// the click reaches the widget. Remember that the press started inside the
// widget, so that change does not close the picker under the cursor. On touch
// screens the compatibility mousedown (which does the blur) comes after
// pointerup, so the flag is set on both and cleared once the click ends, or
// shortly after pointerup when the press ended outside and no click follows.
window.Folio.Input.DateTime.PRESS_EVENTS = ['pointerdown', 'mousedown']
window.Folio.Input.DateTime.RELEASE_DELAYS = { click: 0, pointercancel: 0, pointerup: 500 }
window.Folio.Input.DateTime.FOLLOW_UP_EVENTS = ['mouseup', 'click', 'dblclick']

// A click sequence (double click) that started inside the widget may continue
// outside it, e.g. when the first click picked a day and closed the picker.
// The browser numbers the clicks of one sequence in `e.detail`; the follow-up
// presses and clicks of such a sequence must not reach the page underneath
// (no word selection, no focus change, no link or button activation).
window.Folio.Input.DateTime.continuesWidgetSequence = (state, e, inWidget) => {
  return !inWidget && !!state.widgetDetail && e.detail === state.widgetDetail + 1
}

window.Folio.Input.DateTime.trackPointer = (input) => {
  const state = input.folioInputDateTimeState
  const releaseDelays = window.Folio.Input.DateTime.RELEASE_DELAYS

  const inWidget = (target) => {
    const picker = input.folioInputTempusDominus
    const widget = picker && picker.display.widget
    return !!widget && widget.contains(target)
  }

  const swallow = (e) => {
    e.preventDefault()
    e.stopImmediatePropagation()
  }

  const onPress = (e) => {
    const pressedInWidget = inWidget(e.target)
    window.clearTimeout(state.releaseTimer)
    state.pointerInWidget = pressedInWidget
    if (e.type !== 'mousedown') return

    if (window.Folio.Input.DateTime.continuesWidgetSequence(state, e, pressedInWidget)) {
      state.widgetDetail = e.detail
      state.swallowDetail = e.detail
      swallow(e)
      return
    }

    state.widgetDetail = pressedInWidget ? e.detail : null
    state.swallowDetail = null
  }

  const onFollowUp = (e) => {
    if (state.swallowDetail && e.detail === state.swallowDetail && !inWidget(e.target)) swallow(e)
  }

  const onRelease = (e) => {
    window.clearTimeout(state.releaseTimer)
    state.releaseTimer = window.setTimeout(() => { state.pointerInWidget = false }, releaseDelays[e.type])
  }

  window.Folio.Input.DateTime.PRESS_EVENTS.forEach((type) => document.addEventListener(type, onPress, true))
  window.Folio.Input.DateTime.FOLLOW_UP_EVENTS.forEach((type) => document.addEventListener(type, onFollowUp, true))
  Object.keys(releaseDelays).forEach((type) => document.addEventListener(type, onRelease, true))

  state.untrackPointer = () => {
    window.clearTimeout(state.releaseTimer)
    window.Folio.Input.DateTime.PRESS_EVENTS.forEach((type) => document.removeEventListener(type, onPress, true))
    window.Folio.Input.DateTime.FOLLOW_UP_EVENTS.forEach((type) => document.removeEventListener(type, onFollowUp, true))
    Object.keys(releaseDelays).forEach((type) => document.removeEventListener(type, onRelease, true))
  }
}

// A change made by a widget action is decided after the action (wrapActions).
// A change from outside the widget (typed value, default value, host code,
// also host code reacting to the events dispatched below) closes the picker
// when the input is cleared, gets its first date or jumps by more than an hour,
// as before; not while the pointer is pressed on the widget.
window.Folio.Input.DateTime.shouldHideOnChange = (input, e) => {
  const state = input.folioInputDateTimeState

  if (state && state.action && !state.dispatching) {
    // with keepInvalid a rejected pick still emits a change, marked invalid
    if (e.isValid !== false) state.changed = true
    return false
  }

  if (state && state.pointerInWidget) return false
  if (input.value === '') return true
  if (e.date && !e.oldDate) return true

  return !!(e.date && e.oldDate && Math.abs(e.date - e.oldDate) > window.Folio.Input.DateTime.HOUR_MS + 1)
}

window.Folio.Input.DateTime.makeOnChange = (input) => (e) => {
  if (window.Folio.Input.DateTime.shouldHideOnChange(input, e)) {
    window.Folio.Input.DateTime.hidePicker(input)
  }

  if (e.date === e.oldDate) return

  const state = input.folioInputDateTimeState
  const wasDispatching = state ? state.dispatching : false
  if (state) state.dispatching = true

  try {
    input.dispatchEvent(new window.Event('input', { bubbles: true }))
    input.dispatchEvent(new window.Event('change', { bubbles: true }))
  } finally {
    if (state) state.dispatching = wasDispatching
  }
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
  input.folioInputDateTimeState = { action: null, changed: false, dispatching: false, pointerInWidget: false }
  window.Folio.Input.DateTime.wrapActions(input)
  window.Folio.Input.DateTime.trackPointer(input)

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

  const state = input.folioInputDateTimeState

  if (state) {
    if (state.untrackPointer) state.untrackPointer()
    if (state.restoreActions) state.restoreActions()
    input.folioInputDateTimeState = null
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
