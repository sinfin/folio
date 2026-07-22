window.Folio.Stimulus.register('f-c-files-artwork-form', class extends window.Stimulus.Controller {
  onChange (e) {
    if (!e.target || e.target.dataset.fCFilesPickerTarget !== 'fileIdInput') return

    const form = this.element.querySelector('form')
    if (form) form.requestSubmit()
  }
})
