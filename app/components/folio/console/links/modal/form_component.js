window.Folio.Stimulus.register('f-c-links-modal-form', class extends window.Stimulus.Controller {
  static targets = ["hrefInput"]

  onSubmit (e) {
    e.preventDefault()
    const data = window.Folio.formToHash(e.target)

    if (typeof data.target === 'object') {
      data.target = data.target[0]
    }

    this.dispatch('submit', { detail: { data } })
  }

  onCancelClick (e) {
    e.preventDefault()
    this.dispatch('cancel')
  }
})
