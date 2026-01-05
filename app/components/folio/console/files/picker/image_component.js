window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.Files = window.FolioConsole.Files || {}
window.FolioConsole.Files.Picker = window.FolioConsole.Files.Picker || {}
window.FolioConsole.Files.Picker.Image = window.FolioConsole.Files.Picker.Image || {}

window.FolioConsole.Files.Picker.Image.create = (serializedFile) => {
  const thumb = document.createElement('div')

  thumb.classList.add('f-c-files-picker-image')
  thumb.dataset.controller = 'f-c-files-picker-image'
  thumb.dataset.file = JSON.stringify(serializedFile)

  return thumb
}

window.Folio.Stimulus.register('f-c-files-picker-image', class extends window.Stimulus.Controller {
  connect () {
    const file = JSON.parse(this.element.dataset.file)
    const fileAttributes = file.attributes

    this.element.innerHTML = ''
    this.setDominantColor(fileAttributes)
    this.addPicture(fileAttributes)
    this.addChangeOverlay(fileAttributes)

    window.FolioConsole.Files.Picker.addControlsForStimulusController({
      element: this.element,
      parent: this.element,
      className: 'f-c-files-picker-image'
    })
  }

  setDominantColor (fileAttributes) {
    if (fileAttributes.dominant_color) {
      this.element.style.backgroundColor = fileAttributes.dominant_color
    }
  }

  addPicture (fileAttributes) {
    const picture = document.createElement('picture')
    picture.className = 'f-c-files-picker-image__picture'

    if (fileAttributes.webp_thumb) {
      const source = document.createElement('source')
      source.srcset = fileAttributes.webp_thumb
      source.type = 'image/webp'
      picture.appendChild(source)
    }

    const img = document.createElement('img')
    img.className = 'f-c-files-picker-image__img'
    img.src = fileAttributes.thumb

    picture.appendChild(img)

    this.element.appendChild(picture)
  }

  addChangeOverlay () {
    const overlay = document.createElement('div')
    overlay.className = 'f-c-files-picker-image__action'
    overlay.dataset.action = 'click->f-c-files-picker#onBtnClick'

    if (window.FolioConsole && window.FolioConsole.Ui && window.FolioConsole.Ui.Button) {
      overlay.appendChild(window.FolioConsole.Ui.Button.create({
        icon: 'swap_horizontal',
        variant: 'gray-medium-dark',
        class: 'f-c-files-picker-image__action-btn'
      }))
    }

    this.element.appendChild(overlay)
  }
})
