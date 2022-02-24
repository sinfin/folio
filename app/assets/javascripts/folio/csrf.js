window.Folio = window.Folio || {}
window.Folio.Csrf = {}

window.Folio.Csrf.tokenParam = $('meta[name="csrf-param"]').prop('content')

window.Folio.Csrf.reset = () => {
  window.Folio.Csrf.loading = false
  window.Folio.Csrf.token = null
}

window.Folio.Csrf.reset(0)

window.Folio.Csrf.withToken = (callback) => {
  window.Folio.Csrf.loading = true

  $.get('/csrf').then((value) => {
    window.Folio.Csrf.token = value
    window.Folio.Csrf.loading = false
    $('meta[name="csrf-token"]').prop('content', value)

    if (callback) callback(value)
  })
}

$(document).on('turbolinks:load', () => { window.Folio.Csrf.value = null })
