window.Folio.Stimulus.register('f-dropzone', class extends window.Stimulus.Controller {
  static values = {
    records: Array,
    dict: Object,
    fileType: String,
    fileHumanType: String,
    destroyUrl: { type: String, default: '' },
    maxFileSize: { type: Number, default: 0 },
    persistedFileCount: Number,
  }

  static targets = ['trigger', 'previews', 'previewTemplate']

  connect () {
    this.element.classList.add('dropzone')

    this.dropzone = window.Folio.S3Upload.createDropzone({
      element: document.body,
      fileType: this.fileTypeValue,
      fileHumanType: this.fileHumanTypeValue,
      dontRemoveFileOnSuccess: true,
      maxFileSize: this.maxFileSizeValue,
      onSuccess: () => { this.onCountChange() },
      dropzoneOptions: {
        ...this.dictValue,
        clickable: this.triggerTarget,
        createImageThumbnails: this.fileHumanTypeValue === "image",
        previewsContainer: this.previewsTarget,
        previewTemplate: this.previewTemplateTarget.innerHTML
      }
    })

    this.dropzone.on('removedfile', (file) => { this.removedFile(file) })

    this.recordsValue.forEach((record) => {
      const file = {
        id: record.id,
        name: record.file_name,
        size: record.file_size
      }

      this.dropzone.files.push(file)
      this.dropzone.emit('addedfile', file)

      if (record.thumb) {
        this.dropzone.emit('thumbnail', file, record.thumb)
      }

      return this.dropzone.emit('complete', file)
    })
  }

  disconnect () {
    this.element.classList.remove('dropzone')

    if (this.dropzone) {
      window.Folio.S3Upload.destroyDropzone(this.dropzone)
      delete this.dropzone
    }
  }

  removedFile (file) {
    this.onCountChange()
    if (!this.destroyUrlValue) return

    if (file.status !== 'error' && file.id) {
      const url = this.destroyUrlValue.replace('ID', file.id)
      window.Folio.Api.apiDelete(url)
    }
  }

  onCountChange () {
    let count = 0

    if (this.dropzone && this.dropzone.files) {
      this.dropzone.files.forEach((file) => {
        if (file.id) { count += 1 }
      })
    }

    this.persistedFileCountValue = count
    this.dispatch('persistedFileCountChange', { detail: { count }})
  }
})
