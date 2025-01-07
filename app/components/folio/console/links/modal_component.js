window.Folio.Stimulus.register('f-c-links-modal', class extends window.Stimulus.Controller {
  openWithData (data) {
    console.log(data)
    window.Folio.Modal.open(this.element)
  }

  onCancelClick (e) {
    e.preventDefault()
  }

  onSubmit (e) {
    e.preventDefault()
    console.log('submit')
  }
})
