window.Folio = window.Folio || {}

window.Folio.Confirm = window.Folio.Confirm || {}

window.Folio.Confirm.I18n = {
  cs: {
    delete: "Smazat?",
    remove: "Odebrat?",
  },
  en: {
    delete: "Delete?",
    remove: "Remove?",
  }
}

window.Folio.Confirm.confirm = (key, fn) => {
  if (window.confirm(window.Folio.i18n(window.Folio.Confirm.I18n, key))) {
    fn()
  }
}

Object.keys(window.Folio.Confirm.I18n.cs).forEach((key) => {
  window.Folio.Confirm[key] = (fn) => {
    window.Folio.Confirm.confirm(key, fn)
  }
})
