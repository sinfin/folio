//= require folio/number_to_human_size

window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.Files = window.FolioConsole.Files || {}
window.FolioConsole.Files.Picker = window.FolioConsole.Files.Picker || {}
window.FolioConsole.Files.Picker.Document = window.FolioConsole.Files.Picker.Document || {}

window.FolioConsole.Files.Picker.Document.create = (serializedFile) => {
  const doc = document.createElement('div')

  doc.classList.add('f-c-files-picker-document')
  doc.dataset.controller = 'f-c-files-picker-document'
  doc.dataset.file = JSON.stringify(serializedFile)

  return doc
}

window.Folio.Stimulus.register('f-c-files-picker-document', class extends window.Stimulus.Controller {
  connect () {
    const file = JSON.parse(this.element.dataset.file)
    const fileAttributes = file.attributes

    this.element.innerHTML = ''
    this.addDocument(fileAttributes)
  }

  addDocument (fileAttributes) {
    const div = document.createElement('div')
    div.className = 'f-c-files-picker-document__document'

    const ext = document.createElement('div')
    ext.className = 'f-c-files-picker-document__ext'
    ext.innerText = fileAttributes.extension || '?'
    div.appendChild(ext)

    const name = document.createElement('div')
    name.className = 'f-c-files-picker-document__name'
    name.innerText = fileAttributes.file_name || 'Unknown file name'
    div.appendChild(name)

    const size = document.createElement('div')
    size.className = 'f-c-files-picker-document__size'
    size.innerText = fileAttributes.file_size ? window.Folio.numberToHumanSize(fileAttributes.file_size) : 'Unknown file size'
    div.appendChild(size)

    const btns = document.createElement('div')
    btns.className = 'f-c-files-picker-document__btns'
    window.FolioConsole.Files.Picker.addControlsForStimulusController({
      element: this.element,
      parent: btns,
      className: 'f-c-files-picker-document'
    })
    div.appendChild(btns)

    this.element.appendChild(div)
  }
})
