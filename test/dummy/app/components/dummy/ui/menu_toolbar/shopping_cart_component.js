window.Folio.Stimulus.register('d-ui-menu-toolbar-shopping-cart', class extends window.Stimulus.Controller {
  clicked (e) {
    e.preventDefault()
    this.dispatch("clicked")
    this.toggleClassModifier("active")
  }

  toggleClassModifier (modifier) {
    this.element.classList.toggle(`d-ui-menu-toolbar-shopping-cart--${modifier}`)
  }
})
