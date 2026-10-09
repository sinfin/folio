window.Folio.Stimulus.register('f-ai-c-input-controls', class extends window.Stimulus.Controller {
  toggle (event) {
    this.stop(event)
    this.dispatch('toggle')
  }

  undo (event) {
    this.stop(event)
    this.dispatch('undo')
  }

  stop (event) {
    event.preventDefault()
    event.currentTarget.blur()
  }
})
