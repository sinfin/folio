window.Folio.Stimulus.register('f-file-list', class extends window.Stimulus.Controller {
  static values = {
    fileType: String
  }

  static targets = ['fileTemplate', 'uppy']

  uppyUploadSuccess (event) {
    const { file, result } = event.detail

    const fileElement = this.fileTemplateTarget.content.children[0].cloneNode(true)
    fileElement.dataset.fFileListFileTemplateDataValue = JSON.stringify({
      preview: file.preview
    })
    fileElement.dataset.fFileListFileS3PathValue = new URL(result.uploadURL).pathname.replace(/^\//, '')
    fileElement.dataset.fFileListFileFileTypeValue = this.fileTypeValue

    const flexItem = document.createElement('div')
    flexItem.classList.add('f-file-list__flex-item')
    flexItem.appendChild(fileElement)

    this.uppyTarget.insertAdjacentElement('afterend', flexItem)
  }

  tableViewChange (e) {
    if (!this.element.classList.contains('f-file-list--view-changeable')) return

    const asTable = !!e.detail.images_table_view

    this.element.classList.toggle('f-file-list--view-grid', !asTable)
    this.element.classList.toggle('f-file-list--view-table', asTable)
  }
})
