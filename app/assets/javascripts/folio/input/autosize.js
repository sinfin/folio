//= require autosize/dist/autosize

window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.Autosize = {}

window.Folio.Input.Autosize.bind = (input) => {
  window.autosize(input)
}

window.Folio.Input.Autosize.unbind = (input) => {
  window.autosize.destroy(input)
}

window.Folio.Stimulus.register('f-input-autosize', class extends window.Stimulus.Controller {
  connect () {
    window.Folio.Input.Autosize.bind(this.element)
  }

  disconnect () {
    window.Folio.Input.Autosize.unbind(this.element)
  }
})
