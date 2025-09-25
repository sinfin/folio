//= require folio/input/embed/inner_component

window.Folio = window.Folio || {}
window.Folio.Embed = window.Folio.Embed || {}
window.Folio.Embed.loggingEnabled = window.Folio.Embed.loggingEnabled || false

window.Folio.Embed.getTypeForUrl = (string) => {
  return null
}

window.Folio.Stimulus.register('f-input-embed', class extends window.Stimulus.Controller {
  static targets = ['input', 'iframe', 'loader']
})
