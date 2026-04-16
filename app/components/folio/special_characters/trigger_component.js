window.Folio.Stimulus.register('f-special-characters-trigger', class extends window.Stimulus.Controller {
  toggle () {
    document.dispatchEvent(new CustomEvent('f-special-characters-trigger:toggle', { bubbles: true }))
  }
})
