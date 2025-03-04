window.Folio = window.Folio || {}

window.Folio.Confirm = window.Folio.Confirm || {}

window.Folio.Confirm.I18n = {
  cs: {
    default: 'Opravdu?',
    delete: 'Smazat?',
    remove: 'Odebrat?'
  },
  en: {
    default: 'Are you sure?',
    delete: 'Delete?',
    remove: 'Remove?'
  }
}

window.Folio.Confirm.confirm = (fn, key) => {
  if (window.confirm(window.Folio.i18n(window.Folio.Confirm.I18n, key || 'default'))) {
    fn()
    return true
  }

  return false
}

window.Folio.Confirm.message = (fn, message) => {
  if (window.confirm(message)) {
    fn()
    return true
  }

  return false
}

Object.keys(window.Folio.Confirm.I18n.cs).forEach((key) => {
  window.Folio.Confirm[key] = (fn) => window.Folio.Confirm.confirm(fn, key)
})
