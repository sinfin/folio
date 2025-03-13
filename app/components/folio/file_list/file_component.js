window.Folio.Stimulus.register('f-file-list-file', class extends window.Stimulus.Controller {
  static targets = ['imageWrap', 'loader']

  static values = {
    templateData: { type: String, default: '' }
  }

  connect () {
    if (this.templateDataValue) {
      this.fillTemplate()
    }
  }

  fillTemplate () {
    const data = JSON.parse(this.templateDataValue)

    if (data.file && data.file.preview) {
      const img = document.createElement('img')
      img.classList.add('f-file-list-file__image')
      img.src = data.file.preview
      this.imageWrapTarget.appendChild(img)
    }

    if (this.hasLoaderTarget) {
      this.loaderTarget.remove()
    }
  }
})
