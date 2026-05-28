window.Folio = window.Folio || {}

window.Folio.Confirm = window.Folio.Confirm || {}

window.Folio.Confirm.I18n = {
  cs: {
    default: 'Opravdu?',
    delete: 'Smazat?',
    remove: 'Odebrat?',
    batchUploadInFlight: 'Některé fotky se ještě nahrávají nebo zpracovávají. Pokud uložíte teď, změny se nepoužijí na fotky, které ještě nejsou hotové. Uložit i tak?'
  },
  en: {
    default: 'Are you sure?',
    delete: 'Delete?',
    remove: 'Remove?',
    batchUploadInFlight: "Some photos are still uploading or processing. If you save now, the changes won't apply to photos that aren't finished yet. Save anyway?"
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
