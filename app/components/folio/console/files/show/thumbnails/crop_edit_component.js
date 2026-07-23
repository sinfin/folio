window.Folio.Stimulus.register('f-c-files-show-thumbnails-crop-edit', class extends window.Stimulus.Controller {
  static values = {
    state: String,
    cropperData: Object,
    apiUrl: String,
    apiData: Object
  }

  static targets = ['contain', 'image', 'overlay']

  startEditing () {
    if (this.overlayTarget.open) return

    this.cropPosition = this.initialCropPosition()
    this.stateValue = 'loading-javascript'
    this.openOverlay()

    window.Folio.RemoteScripts.run({
      key: 'cropperjs',
      urls: ['https://cdnjs.cloudflare.com/ajax/libs/cropperjs/2.1.1/cropper.min.js']
    }, () => {
      if (!this.overlayTarget.open) return

      this.initializeCropper()
    }, () => {
      this.cancelEditing()
    })
  }

  saveEditing () {
    if (this.stateValue !== 'editing' || !this.cropperSelection) return

    const crop = this.currentCropPosition()
    const data = {
      ...this.apiDataValue,
      crop
    }

    this.stateValue = 'saving'

    window.Folio.Api.apiPatch(this.apiUrlValue, data).then((res) => {
      if (!res || !res.data) throw new Error('Invalid response from server')

      this.closeOverlay()
      this.unbindCropper()
      this.replaceThumbnails(res.data)
    }).catch((error) => {
      console.error('Failed to save crop', error)
      this.stateValue = 'editing'
    })
  }

  cancelEditing (event) {
    event?.preventDefault()
    this.closeOverlay()
    this.unbindCropper()
    this.stateValue = 'viewing'
  }

  trackBackdropPointerDown (event) {
    this.backdropPointerDown = event.target === this.overlayTarget
    this.backdropPointerUp = false
  }

  trackBackdropPointerUp (event) {
    this.backdropPointerUp = event.target === this.overlayTarget
  }

  cancelEditingFromBackdrop (event) {
    const shouldCancel = this.backdropPointerDown &&
      this.backdropPointerUp &&
      event.target === this.overlayTarget

    this.backdropPointerDown = false
    this.backdropPointerUp = false

    if (shouldCancel) this.cancelEditing(event)
  }

  disconnect () {
    this.closeOverlay()
    this.unbindCropper()
  }

  initializeCropper () {
    this.stateValue = 'setting-cropperjs'
    this.destroyCropper()

    try {
      this.cropper = new window.Cropper.default(this.imageTarget, { // eslint-disable-line new-cap
        template: this.cropperTemplate()
      })
      this.cropperCanvas = this.cropper.getCropperCanvas()
      this.cropperImage = this.cropper.getCropperImage()
      this.cropperSelection = this.cropper.getCropperSelection()
    } catch (error) {
      console.error('Failed to initialize cropper', error)
      this.cancelEditing()
      return
    }

    const cropperImage = this.cropperImage

    cropperImage.$ready(() => {
      if (cropperImage !== this.cropperImage || !this.overlayTarget.open) return

      this.initializationTimeout = window.setTimeout(() => {
        if (cropperImage !== this.cropperImage || !this.overlayTarget.open) return

        cropperImage.$center('contain')
        cropperImage.scalable = false
        cropperImage.translatable = false

        this.initializationFrame = window.requestAnimationFrame(() => {
          if (cropperImage !== this.cropperImage || !this.overlayTarget.open) return

          this.cropperImageBounds = this.measureImageBounds()
          this.clipCropperCanvasToImage()
          this.layoutSelection(this.cropPosition)
          this.bindSelectionBoundary()
          this.observeContain()
          this.containSize = this.currentContainSize()
          this.stateValue = 'editing'
        })
      }, 0)
    }).catch((error) => {
      console.error('Failed to load cropper image', error)
      this.cancelEditing()
    })
  }

  cropperTemplate () {
    return `
      <cropper-canvas>
        <cropper-image initial-center-size="contain" scalable translatable></cropper-image>
        <cropper-selection aspect-ratio="${this.cropperDataValue.aspect_ratio}" movable precise>
          <cropper-grid role="grid" bordered covered></cropper-grid>
          <cropper-crosshair centered></cropper-crosshair>
          <cropper-handle action="move" theme-color="transparent"></cropper-handle>
        </cropper-selection>
      </cropper-canvas>
    `
  }

  layoutSelection (cropPosition) {
    const bounds = this.cropperImageBounds
    if (!bounds) return

    const size = this.selectionSize(bounds)
    const x = bounds.x + this.clamp(cropPosition.x * bounds.width, 0, bounds.width - size.width)
    const y = bounds.y + this.clamp(cropPosition.y * bounds.height, 0, bounds.height - size.height)

    this.cropperSelection.$change(x, y, size.width, size.height, this.cropperDataValue.aspect_ratio)
  }

  selectionSize (bounds) {
    const aspectRatio = this.cropperDataValue.aspect_ratio

    if (bounds.width / bounds.height > aspectRatio) {
      return {
        width: bounds.height * aspectRatio,
        height: bounds.height
      }
    }

    return {
      width: bounds.width,
      height: bounds.width / aspectRatio
    }
  }

  measureImageBounds () {
    if (!this.cropperCanvas || !this.cropperImage) return null

    const canvasRect = this.cropperCanvas.getBoundingClientRect()
    const imageRect = this.cropperImage.getBoundingClientRect()
    if (!canvasRect.width || !canvasRect.height || !imageRect.width || !imageRect.height) return null

    return {
      x: imageRect.left - canvasRect.left,
      y: imageRect.top - canvasRect.top,
      width: imageRect.width,
      height: imageRect.height,
      canvasWidth: canvasRect.width,
      canvasHeight: canvasRect.height
    }
  }

  clipCropperCanvasToImage () {
    const bounds = this.cropperImageBounds
    if (!bounds || !this.cropperCanvas) return

    const right = this.clamp(bounds.canvasWidth - bounds.x - bounds.width, 0, bounds.canvasWidth)
    const bottom = this.clamp(bounds.canvasHeight - bounds.y - bounds.height, 0, bounds.canvasHeight)

    this.cropperCanvas.style.clipPath = `inset(${bounds.y}px ${right}px ${bottom}px ${bounds.x}px)`
  }

  bindSelectionBoundary () {
    // Cropper has no axis lock. Coalesce corrections instead of canceling
    // every change event, which makes dragging laggy.
    this.boundaryChangeHandler = () => {
      if (this.isConstrainingSelection || this.boundaryConstraintFrame) return

      this.boundaryConstraintFrame = window.requestAnimationFrame(() => {
        this.boundaryConstraintFrame = null
        this.constrainSelection()
      })
    }

    // Flush the correction when the pointer interaction ends.
    this.boundaryEndHandler = () => {
      window.cancelAnimationFrame(this.boundaryConstraintFrame)
      this.boundaryConstraintFrame = null
      this.constrainSelection()
    }

    this.cropperSelection.addEventListener('change', this.boundaryChangeHandler)
    this.cropperCanvas.addEventListener('actionend', this.boundaryEndHandler)
  }

  constrainSelection () {
    // $change emits another change event; avoid scheduling recursively.
    this.isConstrainingSelection = true

    try {
      this.constrainSelectionToImage()
    } finally {
      this.isConstrainingSelection = false
    }
  }

  constrainSelectionToImage () {
    const bounds = this.cropperImageBounds
    const selection = this.cropperSelection
    if (!bounds || !selection || this.selectionWithinImage(selection)) return

    const x = this.clamp(selection.x, bounds.x, bounds.x + bounds.width - selection.width)
    const y = this.clamp(selection.y, bounds.y, bounds.y + bounds.height - selection.height)

    selection.$change(x,
      y,
      selection.width,
      selection.height,
      this.cropperDataValue.aspect_ratio)
  }

  selectionWithinImage (selection) {
    const bounds = this.cropperImageBounds
    if (!bounds) return false

    const tolerance = 0.5

    return selection.x >= bounds.x - tolerance &&
      selection.y >= bounds.y - tolerance &&
      selection.x + selection.width <= bounds.x + bounds.width + tolerance &&
      selection.y + selection.height <= bounds.y + bounds.height + tolerance
  }

  currentCropPosition (bounds = this.cropperImageBounds) {
    if (!bounds || !this.cropperSelection) return this.cropPosition || this.initialCropPosition()

    return {
      x: this.normalizedCropOffset(this.cropperSelection.x - bounds.x, bounds.width),
      y: this.normalizedCropOffset(this.cropperSelection.y - bounds.y, bounds.height)
    }
  }

  normalizedCropOffset (offset, dimension) {
    return Math.floor(this.clamp(offset / dimension, 0, 1) * 10000) / 10000
  }

  initialCropPosition () {
    return {
      x: this.cropperDataValue.x,
      y: this.cropperDataValue.y
    }
  }

  observeContain () {
    if (!window.ResizeObserver || this.resizeObserver) return

    this.resizeObserver = new window.ResizeObserver(() => {
      if (this.stateValue !== 'editing' || this.hasSameContainSize()) return

      window.clearTimeout(this.resizeTimeout)
      this.resizeTimeout = window.setTimeout(() => {
        if (this.stateValue !== 'editing') return

        this.cropPosition = this.currentCropPosition(this.measureImageBounds())
        this.initializeCropper()
      }, 150)
    })
    this.resizeObserver.observe(this.containTarget)
  }

  currentContainSize () {
    return {
      width: this.containTarget.clientWidth,
      height: this.containTarget.clientHeight
    }
  }

  hasSameContainSize () {
    if (!this.containSize) return false

    const size = this.currentContainSize()

    return Math.abs(size.width - this.containSize.width) < 0.5 &&
      Math.abs(size.height - this.containSize.height) < 0.5
  }

  replaceThumbnails (html) {
    const current = this.element.closest('.f-c-files-show-thumbnails')
    if (!current) return

    const disclosureWasOpen = current.querySelector('.f-c-files-show-thumbnails__all')?.open
    const template = document.createElement('template')
    template.innerHTML = html.trim()
    const replacement = template.content.firstElementChild
    if (!replacement) return

    const replacementDisclosure = replacement.querySelector('.f-c-files-show-thumbnails__all')
    if (disclosureWasOpen && replacementDisclosure) replacementDisclosure.open = true

    current.replaceWith(replacement)
  }

  openOverlay () {
    if (!this.overlayTarget.open) {
      this.overlayTarget.showModal()
      document.activeElement?.blur()
    }
  }

  closeOverlay () {
    if (this.overlayTarget.open) this.overlayTarget.close()
  }

  unbindCropper () {
    this.resizeObserver?.disconnect()
    window.clearTimeout(this.resizeTimeout)

    this.resizeObserver = null
    this.resizeTimeout = null
    this.containSize = null
    this.destroyCropper()
  }

  destroyCropper () {
    window.clearTimeout(this.initializationTimeout)
    window.cancelAnimationFrame(this.initializationFrame)

    if (this.cropperSelection && this.boundaryChangeHandler) {
      this.cropperSelection.removeEventListener('change', this.boundaryChangeHandler)
    }
    if (this.cropperCanvas && this.boundaryEndHandler) {
      this.cropperCanvas.removeEventListener('actionend', this.boundaryEndHandler)
    }

    window.cancelAnimationFrame(this.boundaryConstraintFrame)
    this.cropperCanvas?.remove()
    this.imageTarget.style.display = ''

    this.cropper = null
    this.cropperCanvas = null
    this.cropperImage = null
    this.cropperImageBounds = null
    this.cropperSelection = null
    this.boundaryChangeHandler = null
    this.boundaryEndHandler = null
    this.boundaryConstraintFrame = null
    this.isConstrainingSelection = false
    this.initializationTimeout = null
    this.initializationFrame = null
  }

  clamp (value, minimum, maximum) {
    return Math.min(Math.max(value, minimum), Math.max(minimum, maximum))
  }

  thumbnailUpdated () {
    if (this.stateValue === 'waiting-for-thumbnail') {
      this.stateValue = 'viewing'
    }
  }
})
