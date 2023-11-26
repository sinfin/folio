window.Folio.Stimulus.register('d-ui-header', class extends window.Stimulus.Controller {
  static targets = ['menu', 'toolbar']

  connect () {
    window.addEventListener('search:open', this.toggleClasses.bind(this))
    window.addEventListener('search:close', this.toggleClasses.bind(this))
  }

  disconnect () {
    window.removeEventListener('search:open', this.toggleClasses.bind(this))
    window.removeEventListener('search:close', this.toggleClasses.bind(this))
  }

  toggleClasses (e) {
    const isOpen = e.type == "search:open"

    if (isOpen) {
      this.menuTarget.classList.add("d-ui-header__menu--hidden")
      this.toolbarTarget.classList.add("d-ui-header__toolbar--expanded")
    } else {
      this.menuTarget.classList.remove("d-ui-header__menu--hidden")
      this.toolbarTarget.classList.remove("d-ui-header__toolbar--expanded")
    }
  }
})
  