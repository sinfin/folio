window.Folio = window.Folio || {}

window.Folio.Confirm = window.Folio.Confirm || {}

window.Folio.Confirm.I18n = {
  cs: {
    default: 'Opravdu?',
    delete: 'Smazat?',
    remove: 'Odebrat?',
    batchUploadInFlight: 'Některé soubory ještě nejsou plně zpracované a vaše úpravy se u nich neobjeví. Chcete změny i tak uložit?'
  },
  en: {
    default: 'Are you sure?',
    delete: 'Delete?',
    remove: 'Remove?',
    batchUploadInFlight: "Some files aren't fully processed yet and your changes won't appear on them. Do you want to save the changes anyway?"
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
