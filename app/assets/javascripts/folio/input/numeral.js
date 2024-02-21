//= require folio/input/_framework
//= require cleave.js/dist/cleave

window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.Numeral = {}

window.Folio.Input.Numeral.cleaveOpts = {
  numeral: true,
  numeralDecimalScale: 6,
  delimiter: ' ',
  onValueChanged: function (e) {
    this.element.nextElementSibling.value = e.target.rawValue
  }
}

window.Folio.Input.Numeral.innerBind = (input) => {
  const name = input.name

  input.dataset.type = input.type
  input.type = 'string'

  input.dataset.name = input.name
  input.removeAttribute('name')

  input.insertAdjacentHTML('afterend', `<input class="f-input__hidden-numeral-input" type="hidden" name="${name}" value="${input.value}" />`)

  input.folioInputNumeralCleave = new window.Cleave(input, window.Folio.Input.Numeral.cleaveOpts)
}

window.Folio.Input.Numeral.bind = (input) => {
  // in console, cleave is included
  if (window.Cleave) {
    window.Folio.Input.Numeral.innerBind(input)
  } else {
    window.Folio.RemoteScripts.run('cleave-js', () => {
      window.Folio.Input.Numeral.innerBind(input)
    })
  }
}

window.Folio.Input.Numeral.unbind = (input) => {
  if (input.dataset.type) { input.type = input.dataset.type }
  if (input.dataset.name) { input.name = input.dataset.name }

  if (input.folioInputNumeralCleave) {
    input.folioInputNumeralCleave.destroy()
    input.folioInputNumeralCleave = null
  }

  const hidden = input.parentNode.querySelector('.f-input__hidden-numeral-input')

  if (hidden) {
    input.value = hidden.value
    hidden.remove()
  }
}

window.Folio.Stimulus.register('f-input-numeral', class extends window.Stimulus.Controller {
  connect () {
    window.Folio.Input.Numeral.bind(this.element)
  }

  disconnect () {
    window.Folio.Input.Numeral.unbind(this.element)
  }
})
