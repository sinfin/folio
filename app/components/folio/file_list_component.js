window.Folio.Stimulus.register('f-file-list', class extends window.Stimulus.Controller {
  static values = {
    fileType: String
  }

  static targets = ['fileTemplate', 'uppy', 'blank', 'thead', 'flexItem']

  connect () {
    // don't handle flexItem targets 64 times on load
    window.setTimeout(() => { this.handleFlexItemTargets = true }, 0)
  }

  uppyUploadSuccess (event) {
    const { file, result } = event.detail

    const fileElement = this.fileTemplateTarget.content.children[0].cloneNode(true)
    fileElement.dataset.fFileListFileTemplateDataValue = JSON.stringify({
      preview: file.preview
    })
    fileElement.dataset.fFileListFileS3PathValue = new URL(result.uploadURL).pathname.replace(/^\//, '')
    fileElement.dataset.fFileListFileFileTypeValue = this.fileTypeValue
    fileElement.querySelector('.f-file-list-file__info-file-name').innerText = file.name

    const flexItem = document.createElement('div')
    flexItem.classList.add('f-file-list__flex-item')
    flexItem.dataset.fFileListTarget = 'flexItem'
    flexItem.appendChild(fileElement)

    this.theadTarget.insertAdjacentElement('afterend', flexItem)
  }

  tableViewChange (e) {
    if (!this.element.classList.contains('f-file-list--view-changeable')) return

    const asTable = !!e.detail.images_table_view

    this.element.classList.toggle('f-file-list--view-grid', !asTable)
    this.element.classList.toggle('f-file-list--view-table', asTable)
  }

  handleCountChange ({ updatePagy }) {
    if (!this.handleFlexItemTargets) return
    this.blankTarget.hidden = this.flexItemTargets.length > 0

    if (updatePagy && window.FolioConsole && window.FolioConsole.Ui && window.FolioConsole.Ui.Pagy) {
      window.FolioConsole.Ui.Pagy.reload()
    }
  }

  flexItemTargetConnected () {
    this.handleCountChange({ updatePagy: false })
  }

  flexItemTargetDisconnected () {
    this.handleCountChange({ updatePagy: true })
  }
})
