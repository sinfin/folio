//= require folio/input/_framework
//= require cleave.js/dist/cleave

window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.Numeral = {}

window.Folio.Input.Numeral.SELECTOR = '.f-input--numeral'

window.Folio.Input.Numeral.cleaveOpts = {
  numeral: true,
  numeralDecimalScale: 6,
  delimiter: ' ',
  onValueChanged: function (e) {
    this.element.nextElementSibling.value = e.target.rawValue
  }
}

window.Folio.Input.Numeral.bind = (input) => {
  const $input = $(input)
  const name = input.name

  $input
    .data('type', input.type)
    .data('name', name)
    .removeAttr('name')
    .prop('type', 'string')

  $input.after(`<input type="hidden" name="${name}" value="${input.value}">`)

  input.folioInputNumeralCleave = new window.Cleave(input, window.Folio.Input.Numeral.cleaveOpts)
}

window.Folio.Input.Numeral.unbind = (input) => {
  const $input = $(input)

  if ($input.data('type')) { $input.prop('type', $input.data('type')) }
  if ($input.data('name')) { $input.prop('name', $input.data('name')) }

  if (input.folioInputNumeralCleave) {
    input.folioInputNumeralCleave.destroy()
    input.folioInputNumeralCleave = null
  }

  const $hidden = $input.next('input[type="hidden"]')

  if ($hidden.length) {
    $input.val($hidden.val())
    $hidden.remove()
  }
}

window.Folio.Input.framework(window.Folio.Input.Numeral)
