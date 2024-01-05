window.Folio.Stimulus.register('d-ui-menu-toolbar-shopping-cart', class extends window.Stimulus.Controller {
  static targets = ['mq']

  clicked (e) {
    const isDesktop = window.Folio.isVisible(this.mqTarget)

    if (!isDesktop) return
    
    e.preventDefault()
    this.dispatch("clicked")
    this.toggleClassModifier("active")
  }

  toggleClassModifier (modifier) {
    this.element.classList.toggle(`d-ui-menu-toolbar-shopping-cart--${modifier}`)
  }

  dropdownClosed ({ detail: { target } }) {
    const $target = document.querySelector(`.${target}`)

    if ($target !== this.element) return

    this.toggleClassModifier("active")
  }
})
