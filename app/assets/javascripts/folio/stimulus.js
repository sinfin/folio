//= require stimulus.umd

window.Folio = window.Folio || {}

window.Folio.Stimulus = window.Folio.Stimulus || {}

window.Folio.Stimulus.APPLICATION = window.Folio.Stimulus.APPLICATION || window.Stimulus.Application.start()

window.Folio.Stimulus.register = window.Folio.Stimulus.register || ((name, klass) => {
  window.Folio.Stimulus.APPLICATION.register(name, klass)
})

document.dispatchEvent(new CustomEvent('folio:stimulus-ready', {
  bubbles: true,
  detail: { stimulus: window.Folio.Stimulus }
}))
