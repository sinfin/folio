window.Folio.Stimulus.register('f-c-files-batch-form', class extends window.Stimulus.Controller {
  onSubmit (e) {
    e.preventDefault()
    const data = window.Folio.formToHash(e.target)

    this.dispatch('submit', { detail: { data } })
  }

  cancel () {
    this.dispatch('cancel')
  }

  fileReloaded () {
    this.dispatch('reload')
  }
})
