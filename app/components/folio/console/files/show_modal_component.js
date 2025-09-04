window.Folio.Stimulus.register('f-c-files-show-modal', class extends window.Stimulus.Controller {
  static values = {
    fileData: Object,
    urlMappings: Object
  }

  static targets = ['navigation', 'navigationButtonPrevious', 'navigationButtonNext']

  fileDataValueChanged (to, from) {
    if (to === from) return

    const { id, type, previousId, nextId } = to || {}

    if (previousId || nextId) {
      this.navigationTarget.hidden = false
      this.navigationButtonPreviousTarget.disabled = !previousId
      this.navigationButtonNextTarget.disabled = !nextId
    } else {
      this.navigationTarget.hidden = true
      this.navigationButtonPreviousTarget.disabled = true
      this.navigationButtonNextTarget.disabled = true
    }

    if (id) {
      if (type && this.urlMappingsValue && this.urlMappingsValue[type]) {
        const url = `${this.urlMappingsValue[type]}/${id}`
        window.Turbo.visit(url, { frame: this.element.querySelector('turbo-frame').id })
        window.Folio.Modal.open(this.element)
      } else {
        console.error(`No URL mapping for file type: ${this.fileTypeValue}`)
        window.Folio.Modal.close(this.element)
      }
    } else {
      window.Folio.Modal.close(this.element)
    }
  }

  disconnect () {
    this.unbindKeyboardEvents()
  }

  onModalOpened () {
    this.bindKeyboardEvents()
  }

  onModalClosed () {
    this.unbindKeyboardEvents()

    if (this.fileDataValue !== {}) {
      this.fileDataValue = {}
    }

    this.element.querySelector('turbo-frame').src = ''
    this.element.querySelector('turbo-frame').innerHTML = ''
  }

  bindKeyboardEvents () {
    this.handleKeydown = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.handleKeydown)
  }

  unbindKeyboardEvents () {
    if (this.handleKeydown) {
      document.removeEventListener('keydown', this.handleKeydown)
      delete this.handleKeydown
    }
  }

  handleKeydown (e) {
    if (e.target && (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA' || e.target.isContentEditable)) {
      return
    }

    if (e.key === 'Escape') {
      e.preventDefault()
      window.Folio.Modal.close(this.element)
    } else if (e.key === 'ArrowLeft') {
      if (this.fileDataValue.previousId) {
        e.preventDefault()
        this.setFileDataValueWithNavigation({
          id: this.fileDataValue.previousId,
          type: this.fileDataValue.type
        })
      }
    } else if (e.key === 'ArrowRight') {
      if (this.fileDataValue.nextId) {
        e.preventDefault()
        this.setFileDataValueWithNavigation({
          id: this.fileDataValue.nextId,
          type: this.fileDataValue.type
        })
      }
    }
  }

  onFileDeleted (e) {
    if (this.fileDataValue !== {}) {
      this.fileDataValue = {}
    }
  }

  onOpenForFileData (e) {
    if (!e || !e.detail) return

    this.setFileDataValueWithNavigation({
      id: e.detail.fileData.id,
      type: e.detail.fileData.type
    })
  }

  setFileDataValueWithNavigation ({ id, type }) {
    const fileSelector = `.f-file-list-file[data-f-file-list-file-file-type-value="${type}"][data-f-file-list-file-editable-value="true"]`
    const fileListFile = document.querySelector(`${fileSelector}[data-f-file-list-file-id-value="${id}"]`)

    let previousId = null
    let nextId = null

    if (fileListFile) {
      const fileListFileParent = fileListFile.closest('.f-file-list__flex-item')

      if (fileListFileParent.nextElementSibling) {
        const nextFile = fileListFileParent.nextElementSibling.querySelector(fileSelector)
        if (nextFile) {
          nextId = Number(nextFile.dataset.fFileListFileIdValue)
        }
      }

      if (fileListFileParent.previousElementSibling) {
        const previousFile = fileListFileParent.previousElementSibling.querySelector(fileSelector)
        if (previousFile) {
          previousId = Number(previousFile.dataset.fFileListFileIdValue)
        }
      }
    }

    this.fileDataValue = {
      id,
      type,
      previousId,
      nextId
    }
  }

  onNavigationClick (e) {
    e.preventDefault()

    if (e.currentTarget.dataset.direction === 'previous') {
      if (this.fileDataValue.previousId) {
        this.setFileDataValueWithNavigation({
          id: this.fileDataValue.previousId,
          type: this.fileDataValue.type
        })
      }
    } else {
      if (this.fileDataValue.nextId) {
        this.setFileDataValueWithNavigation({
          id: this.fileDataValue.nextId,
          type: this.fileDataValue.type
        })
      }
    }
  }
})
