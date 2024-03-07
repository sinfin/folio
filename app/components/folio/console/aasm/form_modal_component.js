window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.AASM = window.FolioConsole.AASM || {}
window.FolioConsole.AASM.FormModal = window.FolioConsole.AASM.FormModal || {}

window.FolioConsole.AASM.FormModal.open = (data) => {
  document
    .querySelector('.f-c-aasm-form-modal')
    .dispatchEvent(new window.CustomEvent('folioConsoleAasmFormModalOpen', { bubbles: true, detail: data }))
}

window.Folio.Stimulus.register('f-c-aasm-form-modal', class extends window.Stimulus.Controller {
  connnect () {
    console.log('f-c-aasm-form-modal')
  }

  openFromEvent (e) {
    console.log('openFromEvent', e.detail)
  }
})
