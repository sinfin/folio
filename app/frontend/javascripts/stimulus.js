import { Application, Controller } from "@hotwired/stimulus"

window.Stimulus = window.Stimulus || {}
window.Stimulus.Application = window.Stimulus.Application || Application
window.Stimulus.Controller = window.Stimulus.Controller || Controller

window.Folio = window.Folio || {}

window.Folio.Stimulus = window.Folio.Stimulus || {}

window.Folio.Stimulus.APPLICATION = window.Stimulus.Application.start()

window.Folio.Stimulus.register = (name, klass) => {
  window.Folio.Stimulus.APPLICATION.register(name, klass)
}

console.log('yuo')
