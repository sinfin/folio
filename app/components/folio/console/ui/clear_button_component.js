window.Folio.Stimulus.register('f-c-ui-clear-button', class extends window.Stimulus.Controller {
  onClick (e) {
    e.preventDefault()
    this.dispatch('click')
  }
})
