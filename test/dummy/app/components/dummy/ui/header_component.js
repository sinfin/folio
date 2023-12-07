window.Folio.Stimulus.register('d-ui-header', class extends window.Stimulus.Controller {
  static targets = ['menu', 'toolbar']

  toggleClass ({ detail: { value } }) {
    if (value) {
      this.element.classList.add("d-ui-header--toolbar-expanded")
    } else {
      this.element.classList.remove("d-ui-header--toolbar-expanded")
    }
  }
})
