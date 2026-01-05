window.Folio.Stimulus.register('f-c-files-show-thumbnails-crop-edit', class extends window.Stimulus.Controller {
  static values = {
    state: String,
    cropperData: Object,
    apiUrl: String,
    mode: String,
    apiData: Object
  }

  static targets = ['editorImage', 'editorInner']

  startEditing () {
    this.stateValue = 'loading-javascript'

    window.Folio.RemoteScripts.run({
      key: 'cropperjs',
      urls: ['https://cdnjs.cloudflare.com/ajax/libs/cropperjs/2.0.1/cropper.min.js']
    }, () => {
      this.stateValue = 'setting-cropperjs'

      const imageWidth = parseFloat(this.editorImageTarget.getAttribute('width'))
      const imageHeight = parseFloat(this.editorImageTarget.getAttribute('height'))

      this.cropper = new window.Cropper.default(this.editorImageTarget, { // eslint-disable-line new-cap
        template: `
          <cropper-canvas background>
            <cropper-image image-fit="none" style="width: ${imageWidth}px; height: ${imageHeight}px;"></cropper-image>
            <cropper-shade hidden></cropper-shade>
            <cropper-selection x="${this.cropperDataValue.x}" y="${this.cropperDataValue.y}" width="${this.cropperDataValue.selection_width}" height="${this.cropperDataValue.selection_height}" movable precise>
              <cropper-grid role="grid" bordered covered></cropper-grid>
              <cropper-crosshair centered></cropper-crosshair>
              <cropper-handle action="move" theme-color="rgba(255, 255, 255, 0.35)"></cropper-handle>
            </cropper-selection>
          </cropper-canvas>
        `
      })

      setTimeout(() => {
        this.setupImageBoundaryConstraint()
        setTimeout(() => { this.stateValue = 'editing' }, 0)
      }, 0)
    }, () => {
      this.stateValue = 'error-loading-javascript'
    })
  }

  saveEditing () {
    if (!this.cropper) return this.cancelEditing()

    const cropperSelection = this.cropperSelection
    const cropperImage = this.cropperSelection?.parentElement?.querySelector('cropper-image')

    if (!cropperSelection || !cropperImage) return this.cancelEditing()

    const x = Math.floor((cropperSelection.x / cropperImage.offsetWidth) * 10000) / 10000
    const y = Math.floor((cropperSelection.y / cropperImage.offsetHeight) * 10000) / 10000

    const cropData = { x: Math.max(0, x), y: Math.max(0, y) }

    const data = {
      ...this.apiDataValue,
      crop: { x: cropData.x, y: cropData.y }
    }

    this.stateValue = 'saving'

    window.Folio.Api.apiPatch(this.apiUrlValue, data).then((res) => {
      if (res && res.data) {
        this.element.closest('.f-c-files-show-thumbnails-ratio').outerHTML = res.data
      } else {
        throw new Error('Invalid response from server')
      }
    }).catch((err) => {
      console.error('Failed to save crop', err)
      this.stateValue = 'editing'
    })
  }

  cancelEditing () {
    this.stateValue = 'viewing'
    this.unbindCropper()
  }

  setupImageBoundaryConstraint () {
    const container = this.editorImageTarget.parentElement
    const cropperCanvas = container.querySelector('cropper-canvas')
    const cropperImage = container.querySelector('cropper-image')
    const cropperSelection = container.querySelector('cropper-selection')

    if (!cropperCanvas || !cropperImage || !cropperSelection) {
      return
    }

    this.boundaryConstraintHandler = (event) => {
      const selection = event.detail
      const cropperImageRect = cropperImage.getBoundingClientRect()

      if (selection.x < 0 || selection.y < 0) {
        return event.preventDefault()
      }

      if (this.modeValue === 'fixed-width') {
        if (selection.x !== 0) {
          return event.preventDefault()
        }

        // y + height cannot exceed image height
        if ((selection.y + selection.height) > cropperImageRect.height) {
          return event.preventDefault()
        }
      } else if (this.modeValue === 'fixed-height') {
        if (selection.y !== 0) {
          return event.preventDefault()
        }

        // x + width cannot exceed image width
        if ((selection.x + selection.width) > cropperImageRect.width) {
          return event.preventDefault()
        }
      }
    }

    cropperSelection.addEventListener('change', this.boundaryConstraintHandler)
    this.cropperSelection = cropperSelection
  }

  selectionWithinBounds (selection, bounds) {
    return (
      selection.x >= Math.floor(bounds.x) &&
      selection.y >= Math.floor(bounds.y) &&
      (selection.x + selection.width) <= Math.ceil(bounds.x + bounds.width) &&
      (selection.y + selection.height) <= Math.ceil(bounds.y + bounds.height)
    )
  }

  disconnect () {
    this.unbindCropper()
  }

  unbindCropper () {
    if (this.cropperSelection && this.boundaryConstraintHandler) {
      this.cropperSelection.removeEventListener('change', this.boundaryConstraintHandler)
    }

    if (this.cropper && typeof this.cropper.destroy === 'function') {
      this.cropper.destroy()
    }

    this.cropper = null
    this.cropperSelection = null
    this.boundaryConstraintHandler = null
  }

  thumbnailUpdated () {
    if (this.stateValue === 'waiting-for-thumbnail') {
      this.stateValue = 'viewing'
    }
  }
})
