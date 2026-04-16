window.Folio.Stimulus.register('f-special-characters-trigger', class extends window.Stimulus.Controller {
  toggleFromDesktop () {
    this.element.dispatchEvent(new CustomEvent('f-special-characters-trigger:toggle', { bubbles: true }))
  }

  toggleFromMobile () {
    document.dispatchEvent(new CustomEvent('f-special-characters-trigger:toggle', { bubbles: true }))
  }

  preventDefault (e) {
    e.preventDefault()
  }
})
