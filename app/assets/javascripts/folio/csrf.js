// TODO jQuery -> stimulus

$.ajaxSetup({
  beforeSend: (xhr) => { Rails.CSRFProtection(xhr) }
})

$(document).on('turbolinks:load', Rails.refreshCSRFTokens)
