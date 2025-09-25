//= require folio/form_to_hash

window.Folio.Stimulus.register('f-c-files-batch-form', class extends window.Stimulus.Controller {
  cancel () {
    this.dispatch('cancel')
  }

  submit () {
    const data = {}

    for (const formControl of this.element.querySelectorAll('input, .form-control')) {
      data[formControl.name] = formControl.value
    }

    this.dispatch('submit', { detail: { data: window.Folio.formToHash(data) } })
  }

  fileReloaded () {
    this.dispatch('reload')
  }

  onKeypress (e) {
    if (e.key !== 'Enter') return
    if (e.target.tagName !== 'INPUT' && e.target.tagName !== 'TEXTAREA') return

    e.preventDefault()
    this.submit()
  }
})
