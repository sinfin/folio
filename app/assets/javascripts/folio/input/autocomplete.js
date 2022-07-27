//= require folio/input/_framework
//= require folio/input/_ui_autocomplete

window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.Autocomplete = {}

window.Folio.Input.Autocomplete.SELECTOR = '.f-input--autocomplete'

window.Folio.Input.Autocomplete.bind = (input) => {
  const $input = $(input)
  $input.autocomplete({ source: $input.data('autocomplete') })
}

window.Folio.Input.Autocomplete.unbind = (input) => {
  $(input).autocomplete('destroy')
}

window.Folio.Input.framework(window.Folio.Input.Autocomplete)
