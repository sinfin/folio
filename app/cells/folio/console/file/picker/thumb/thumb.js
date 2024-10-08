window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.File = window.FolioConsole.File || {}
window.FolioConsole.File.Picker = window.FolioConsole.File.Picker || {}
window.FolioConsole.File.Picker.Thumb = window.FolioConsole.File.Picker.Thumb || {}

window.FolioConsole.File.Picker.Thumb.create = (serializedFile) => {
  const thumb = document.createElement('div')

  thumb.classList.add('f-c-file-picker-thumb')
  thumb.dataset.controller = 'f-c-file-picker-thumb'
  thumb.dataset.file = JSON.stringify(serializedFile)

  return thumb
}

window.Folio.Stimulus.register('f-c-file-picker-thumb', class extends window.Stimulus.Controller {
  connect() {
    const file = JSON.parse(this.element.dataset.file)
    const fileAttributes = file.attributes

    this.element.innerHTML = ""
    this.setDominantColor(fileAttributes)
    this.addPicture(fileAttributes)
    this.addChangeOverlay(fileAttributes)

    window.FolioConsole.File.Picker.addControlsForStimulusController({
      element: this.element,
      parent: this.element,
      className: 'f-c-file-picker-thumb'
    })
  }

  setDominantColor(fileAttributes) {
    if (fileAttributes.dominant_color) {
      this.element.style.backgroundColor = fileAttributes.dominant_color
    }
  }

  addPicture(fileAttributes) {
    const picture = document.createElement('picture')
    picture.className = 'f-c-file-picker-thumb__picture'

    if (fileAttributes.webp_thumb) {
      const source = document.createElement('source')
      source.srcset = fileAttributes.webp_thumb
      source.type = 'image/webp'
      picture.appendChild(source)
    }

    const img = document.createElement('img')
    img.className = 'f-c-file-picker-thumb__img'
    img.src = fileAttributes.thumb

    picture.appendChild(img)

    this.element.appendChild(picture)
  }

  addChangeOverlay() {
    const overlay = document.createElement('div')
    overlay.className = 'f-c-file-picker-thumb__action'
    overlay.dataset.action = 'click->f-c-file-picker#onBtnClick'

    if (window.FolioConsole && window.FolioConsole.Ui && window.FolioConsole.Ui.Button) {
      overlay.appendChild(window.FolioConsole.Ui.Button.create({
        icon: 'swap_horizontal',
        variant: 'gray-medium-dark',
        class: 'f-c-file-picker-thumb__action-btn'
      }))
    }

    this.element.appendChild(overlay)
  }
})
