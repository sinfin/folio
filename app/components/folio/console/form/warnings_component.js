window.Folio.Stimulus.register('f-c-form-warnings', class extends window.Stimulus.Controller {
  openFileShowModal (e) {
    e.preventDefault()

    const trigger = e.currentTarget
    const fileDataJson = trigger.dataset.fileData
    const fileData = fileDataJson ? JSON.parse(fileDataJson) : null

    if (!fileData) return

    const modal = document.querySelector('.f-c-files-show-modal')
    if (!modal) return

    modal.dispatchEvent(new window.CustomEvent('f-c-files-show-modal:openForFileData', {
      detail: { fileData }
    }))
  }
})
