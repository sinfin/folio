window.Folio.Stimulus.register('f-file-list-file-batch-checkbox', class extends window.Stimulus.Controller {
  static targets = ['input']

  // connect () {
  //   if (this.addAutomaticallyValue) {
  //     const batchBar = document.querySelector('.f-c-files-batch-bar')
  //     if (!batchBar) return

  //     const action = 'add'

  //     batchBar.dispatchEvent(new CustomEvent('f-c-files-batch-bar:reload'))
  //   }
  // }

  onGlobalBatchActionCheckboxInput (e) {
    const batchBar = document.querySelector('.f-c-files-batch-bar')
    if (!batchBar) return
    const action = e.target.checked ? 'add-all' : 'remove-all'
    batchBar.dispatchEvent(new CustomEvent('f-c-files-batch-bar:action', { detail: { action } }))
  }

  onBatchActionCheckboxInput (e) {
    const batchBar = document.querySelector('.f-c-files-batch-bar')
    if (!batchBar) return

    const action = e.target.checked ? 'add' : 'remove'

    batchBar.dispatchEvent(new CustomEvent('f-c-files-batch-bar:action', { detail: { action, id: this.inputTarget.value } }))
  }

  batchUpdated (e) {
    this.inputTarget.checked = e.detail.action === 'add'
  }
})
