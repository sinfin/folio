window.Folio.Stimulus.register('d-ui-menu-toolbar-shopping-cart', class extends window.Stimulus.Controller {
  static targets = ['mq']

  static values = {
    active: { type: Boolean, default: false }
  }

  clicked (e) {
    const isDesktop = window.Folio.isVisible(this.mqTarget)
    if (!isDesktop) return

    e.preventDefault()

    if (e.type === "keydown" && e.key === "Escape" && !this.activeValue) return

    if (!this.activeValue) {
      this.activate()
    } else {
      this.deactivate()
    }

    this.dispatch("clicked")
  }

  activate () {
    if (this.activeValue) return

    this.element.classList.add('d-ui-menu-toolbar-shopping-cart--active')
    this.activeValue = true
  }

  deactivate () {
    if (!this.activeValue) return

    this.element.classList.remove('d-ui-menu-toolbar-shopping-cart--active')
    this.activeValue = false
  }

  dropdownClosed ({ detail: { target } }) {
    const $target = document.querySelector(`.${target}`)

    if ($target !== this.element) return

    this.deactivate()
  }
})
