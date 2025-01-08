window.Folio.Stimulus.register('f-c-links-modal-form', class extends window.Stimulus.Controller {
  static targets = ["hrefInput"]

  onSubmit (e) {
    e.preventDefault()
    const data = window.Folio.formToHash(e.target)
    this.dispatch('submit', { detail: { data } })
  }

  onCancelClick (e) {
    e.preventDefault()
    this.dispatch('cancel')
  }
})
