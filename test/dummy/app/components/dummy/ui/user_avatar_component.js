window.Folio.Stimulus.register('d-ui-user-avatar', class extends window.Stimulus.Controller {
  clicked () {
    this.dispatch("clicked")
    this.toggleClassModifier("active")
  }

  toggleClassModifier (modifier) {
    this.element.classList.toggle(`d-ui-user-avatar--${modifier}`)
  }
})
