window.Folio.Stimulus.register('f-c-files-artwork-form', class extends window.Stimulus.Controller {
  static targets = ['form']

  onChange (e) {
    if (!e.target || e.target.dataset.fCFilesPickerTarget !== 'fileIdInput') return

    this.formTarget.requestSubmit()
  }
})
