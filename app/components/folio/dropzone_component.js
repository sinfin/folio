//= require folio/add_params_to_url

window.Folio.Stimulus.register('f-dropzone', class extends window.Stimulus.Controller {
  static values = {
    records: Array,
    dict: Object,
    fileType: String,
    fileHumanType: String,
    destroyUrl: { type: String, default: '' },
    indexUrl: { type: String, default: '' },
    maxFileSize: { type: Number, default: 0 },
    persistedFileCount: Number,
    pendingFileCount: { type: Number, defualt: 0 }
  }

  static targets = ['trigger', 'previews', 'previewTemplate']

  connect () {
    this.disconnected = false

    this.element.classList.add('dropzone')

    this.dropzone = window.Folio.S3Upload.createDropzone({
      element: document.body,
      fileType: this.fileTypeValue,
      fileHumanType: this.fileHumanTypeValue,
      dontRemoveFileOnSuccess: true,
      maxFileSize: this.maxFileSizeValue,
      onStart: () => { this.onCountChange() },
      onSuccess: () => { this.onCountChange() },
      onFailure: (s3Path, message) => {
        window.alert(`${this.dictValue.upload_failure}\n${message}`)
      },
      dropzoneOptions: {
        ...this.dictValue,
        clickable: this.triggerTarget,
        createImageThumbnails: this.fileHumanTypeValue === 'image',
        previewsContainer: this.previewsTarget,
        previewTemplate: this.previewTemplateTarget.innerHTML
      }
    })

    this.dropzone.on('removedfile', (file) => { this.removedFile(file) })

    this.recordsValue.forEach((record) => {
      this.addSerializedRecord(record)
    })

    if (this.indexUrlValue) {
      this.fetchIndex()
    }
  }

  disconnect () {
    this.disconnected = true
    this.element.classList.remove('dropzone')

    if (this.dropzone) {
      window.Folio.S3Upload.destroyDropzone(this.dropzone)
      delete this.dropzone
    }
  }

  removedFile (file) {
    if (this.disconnected) return

    this.onCountChange()
    if (!this.destroyUrlValue) return

    if (file.status !== 'error' && file.id) {
      const url = this.destroyUrlValue.replace('ID', file.id)
      window.Folio.Api.apiDelete(url)
    }
  }

  onCountChange () {
    let persistedCount = 0
    let pendingCount = 0

    if (this.dropzone && this.dropzone.files) {
      this.dropzone.files.forEach((file) => {
        if (file.id) {
          persistedCount += 1
        } else {
          pendingCount += 1
        }
      })
    }

    this.persistedFileCountValue = persistedCount
    this.pendingFileCountValue = pendingCount

    this.dispatch('persistedFileCountChange', { detail: { count: persistedCount } })
    this.dispatch('pendingFileCountChange', { detail: { count: pendingCount } })
  }

  addSerializedRecord (record) {
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

    this.dropzone.emit('complete', file)
  }

  fetchIndex () {
    const url = window.Folio.addParamsToUrl(this.indexUrlValue, { type: this.fileTypeValue })

    window.Folio.Api.apiGet(url).then((res) => {
      res.forEach((record) => {
        this.addSerializedRecord(record)
      })
    })
  }
})
