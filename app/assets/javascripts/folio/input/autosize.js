//= require folio/input/_framework
//= require autosize/dist/autosize

window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.Autosize = {}

window.Folio.Input.Autosize.SELECTOR = '.f-input--autosize'

window.Folio.Input.Autosize.bind = (input) => {
  window.autosize($(input))
}

window.Folio.Input.Autosize.unbind = (input) => {
  $(input).trigger('autosize.destroy')
}

window.Folio.Input.framework(window.Folio.Input.Autosize)
