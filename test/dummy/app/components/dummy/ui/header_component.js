window.Folio.Stimulus.register('d-ui-header', class extends window.Stimulus.Controller {
  toggleDropdownExpandedClass ({ detail: { value } }) {
    if (value) {
      this.element.classList.add("d-ui-header--toolbar-expanded")
    } else {
      this.element.classList.remove("d-ui-header--toolbar-expanded")
    }
  }

  toggleMenuOpenedClass () {
    this.element.classList.toggle("d-ui-header--menu-opened")
  }
})
