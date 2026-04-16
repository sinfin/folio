window.Folio.Stimulus.register('f-special-characters-trigger', class extends window.Stimulus.Controller {
  toggle () {
    this.element.dispatchEvent(new CustomEvent('f-special-characters-trigger:toggle', { bubbles: true }))
  }
})
