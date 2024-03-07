window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.AASM = window.FolioConsole.AASM || {}
window.FolioConsole.AASM.FormModal = window.FolioConsole.AASM.FormModal || {}

window.FolioConsole.AASM.FormModal.open = (data) => {
  document
    .querySelector('.f-c-aasm-form-modal')
    .dispatchEvent(new window.CustomEvent('folioConsoleAasmFormModalOpen', { bubbles: true, detail: data }))
}

window.Folio.Stimulus.register('f-c-aasm-form-modal', class extends window.Stimulus.Controller {
  static classes = ['loading']

  static targets = ['formWrap']

  openFromEvent (e) {
    this.element.classList.add(this.loadingClass)
    window.Folio.Modal.open(this.element)

    window.Folio.Api.apiHtmlGet(e.detail.modalUrl).then((res) => {
      const parser = new window.DOMParser()
      const doc = parser.parseFromString(res, 'text/html')
      const target = doc.querySelector('.f-c-aasm-form-modal-target')

      this.formWrapTarget.innerHTML = target.outerHTML

      this.element.classList.remove(this.loadingClass)
    })
  }
})
