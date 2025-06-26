window.Folio.Stimulus.register('f-c-tiptap-overlay-form', class extends window.Stimulus.Controller {
  static targets = ["form"]

  connect () {
    window.setTimeout(() => {
      const firstInput = this.element.querySelector('.form-control')

      if (firstInput) [
        firstInput.focus()
      ]
    }, 200) // wait for css transition
  }

  onFormSubmit (e) {
    e.preventDefault()
    const data = window.Folio.formToHash(e.target)

    this.dispatch("submit", { detail: { data } })
  }
})
