window.Folio.Stimulus.register('f-c-files-show-thumbnails-crop-edit', class extends window.Stimulus.Controller {
  static values = {
    state: Boolean,
    imageSrc: String,
    cropperData: Object
  }

  static targets = ['editorImage', 'editorInner']

  startEditing () {
    this.stateValue = 'loading-javascript'

    window.Folio.RemoteScripts.run({
      key: 'cropperjs',
      urls: ['https://cdnjs.cloudflare.com/ajax/libs/cropperjs/2.0.1/cropper.min.js']
    }, () => {
      this.cropper = new window.Cropper.default(this.editorImageTarget, { // eslint-disable-line new-cap
        template: `
          <cropper-canvas background>
            <cropper-image image-fit="contain"></cropper-image>
            <cropper-shade hidden></cropper-shade>
            <cropper-handle action="select" plain></cropper-handle>
            <cropper-selection initial-coverage="1" aspect-ratio="${this.cropperDataValue.aspect_ratio}" movable>
              <cropper-grid role="grid" bordered covered></cropper-grid>
              <cropper-crosshair centered></cropper-crosshair>
              <cropper-handle action="move" theme-color="rgba(255, 255, 255, 0.35)"></cropper-handle>
              <cropper-handle action="n-resize"></cropper-handle>
              <cropper-handle action="e-resize"></cropper-handle>
              <cropper-handle action="s-resize"></cropper-handle>
              <cropper-handle action="w-resize"></cropper-handle>
              <cropper-handle action="ne-resize"></cropper-handle>
              <cropper-handle action="nw-resize"></cropper-handle>
              <cropper-handle action="se-resize"></cropper-handle>
              <cropper-handle action="sw-resize"></cropper-handle>
            </cropper-selection>
          </cropper-canvas>
        `
      })

      setTimeout(() => {
        this.setupImageBoundaryConstraint()
      }, 0)
      this.stateValue = 'editing'
    }, () => {
      this.stateValue = 'error-loading-javascript'
    })
  }

  saveEditing () {
    if (!this.cropper) return this.cancelEditing()

    const cropperSelection = this.cropperSelection
    const cropperImage = this.cropperSelection?.parentElement?.querySelector('cropper-image')

    if (!cropperSelection || !cropperImage) return this.cancelEditing()

    const cropData = {
      x: Math.floor((cropperSelection.x / cropperImage.offsetWidth) * 10000) / 10000,
      y: Math.floor((cropperSelection.y / cropperImage.offsetHeight) * 10000) / 10000,
    }

    console.log('saving cropData', cropData)

    this.stateValue = 'saving'
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
      const cropperCanvasRect = cropperCanvas.getBoundingClientRect()
      const cropperImageRect = cropperImage.getBoundingClientRect()

      const imageSelection = {
        x: cropperImageRect.left - cropperCanvasRect.left,
        y: cropperImageRect.top - cropperCanvasRect.top,
        width: cropperImageRect.width,
        height: cropperImageRect.height
      }

      if (!this.selectionWithinBounds(selection, imageSelection)) {
        event.preventDefault()
      }
    }

    cropperSelection.addEventListener('change', this.boundaryConstraintHandler)
    this.cropperSelection = cropperSelection
  }

  selectionWithinBounds (selection, bounds) {
    return (
      selection.x >= bounds.x &&
      selection.y >= bounds.y &&
      (selection.x + selection.width) <= (bounds.x + bounds.width) &&
      (selection.y + selection.height) <= (bounds.y + bounds.height)
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
})
