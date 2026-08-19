window.FolioConsole = window.FolioConsole || {}

window.FolioConsole.FilesShowThumbnailPreviews = {
  eventName: 'f-c-files-show-thumbnails-crop-edit:preview-ready',
  jobType: 'Folio::GenerateThumbnailJob',
  subscriptions: new Map(),
  completed: new Map(),
  cleanupTimeouts: new Map(),

  subscribe ({ element, fileId, candidates, crop }) {
    const normalizedFileId = fileId.toString()

    this.cancelCleanup(normalizedFileId)
    this.subscriptions.set(element, {
      fileId: normalizedFileId,
      candidates,
      crop
    })

    return candidates
      .slice()
      .sort((left, right) => left.priority - right.priority)
      .map(({ size }) => this.completed.get(this.cacheKey(normalizedFileId, size)))
      .filter((detail) => detail && this.cropMatches(crop, detail.thumb))
  },

  beginGeneration ({ element, fileId, candidates, crop }) {
    const normalizedFileId = fileId.toString()

    for (const candidate of candidates) {
      this.completed.delete(this.cacheKey(normalizedFileId, candidate.size))
    }

    this.subscribe({ element, fileId: normalizedFileId, candidates, crop })
  },

  unsubscribe ({ element }) {
    const subscription = this.subscriptions.get(element)
    if (!subscription) return

    this.subscriptions.delete(element)
    this.scheduleCleanup(subscription.fileId)
  },

  handleMessage (message) {
    if (this.subscriptions.size === 0) return
    if (!message || message.type !== this.jobType) return

    const data = message.data
    if (!data?.id || !data.size || !data.url) return

    const detail = {
      id: data.id.toString(),
      size: data.size,
      url: data.url,
      webpUrl: data.webp_url,
      width: data.width,
      height: data.height,
      thumb: data.thumb
    }
    const matches = []

    for (const [element, subscription] of this.subscriptions.entries()) {
      if (this.subscriptionMatches(subscription, detail)) matches.push(element)
    }

    if (!matches.length) return

    this.completed.set(this.cacheKey(detail.id, detail.size), detail)

    for (const element of matches) {
      element.dispatchEvent(new CustomEvent(this.eventName, { detail }))
    }
  },

  subscriptionMatches (subscription, detail) {
    if (subscription.fileId !== detail.id) return false
    if (!subscription.candidates.some(({ size }) => size === detail.size)) return false

    return this.cropMatches(subscription.crop, detail.thumb)
  },

  cropMatches (expectedCrop, thumb) {
    if (!expectedCrop) return true
    if (!thumb) return false

    return ['x', 'y'].every((key) => {
      if (expectedCrop[key] === null || typeof expectedCrop[key] === 'undefined') return false
      if (thumb[key] === null || typeof thumb[key] === 'undefined') return false

      const expected = Number(expectedCrop[key])
      const actual = Number(thumb[key])

      return Number.isFinite(expected) && Number.isFinite(actual) && Math.abs(expected - actual) < 0.000001
    })
  },

  cacheKey (fileId, size) {
    return `${fileId}:${size}`
  },

  scheduleCleanup (fileId) {
    const hasSubscription = Array.from(this.subscriptions.values()).some((subscription) => {
      return subscription.fileId === fileId
    })
    if (hasSubscription || this.cleanupTimeouts.has(fileId)) return

    const timeout = window.setTimeout(() => {
      const stillSubscribed = Array.from(this.subscriptions.values()).some((subscription) => {
        return subscription.fileId === fileId
      })

      if (!stillSubscribed) {
        for (const key of this.completed.keys()) {
          if (key.startsWith(`${fileId}:`)) this.completed.delete(key)
        }
      }

      this.cleanupTimeouts.delete(fileId)
    }, 60000)

    this.cleanupTimeouts.set(fileId, timeout)
  },

  cancelCleanup (fileId) {
    const timeout = this.cleanupTimeouts.get(fileId)
    if (!timeout) return

    window.clearTimeout(timeout)
    this.cleanupTimeouts.delete(fileId)
  }
}

if (window.Folio?.MessageBus?.callbacks) {
  window.Folio.MessageBus.callbacks['f-c-files-show-thumbnail-previews'] = (message) => {
    window.FolioConsole.FilesShowThumbnailPreviews.handleMessage(message)
  }
}

window.Folio.Stimulus.register('f-c-files-show-thumbnails-crop-edit', class extends window.Stimulus.Controller {
  static values = {
    state: String,
    cropperData: Object,
    apiUrl: String,
    apiData: Object,
    fileId: String,
    previewCandidates: Array,
    previewPriority: Number,
    previewCrop: Object
  }

  static targets = ['contain', 'image', 'overlay', 'thumbImage']

  connect () {
    this.subscribePreviewCandidates()
  }

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

  saveEditing (event) {
    if (this.stateValue !== 'editing' || !this.cropperSelection) return

    event?.preventDefault()

    this.saveCrop(this.currentCropPosition(), { closeEditing: true })
  }

  regenerate (event) {
    if (this.stateValue === 'saving') return

    event.preventDefault()
    event.currentTarget.disabled = true

    this.saveCrop(this.initialCropPosition(), { trigger: event.currentTarget })
  }

  saveCrop (crop, { closeEditing = false, trigger = null } = {}) {
    const previousState = this.stateValue
    const data = {
      ...this.apiDataValue,
      crop
    }

    this.beginPreviewGeneration(crop)
    this.stateValue = 'saving'

    window.Folio.Api.apiPatch(this.apiUrlValue, data).then((res) => {
      if (!res || !res.data || !res.data.main || !res.data.details) throw new Error('Invalid response from server')

      if (closeEditing) {
        this.closeOverlay()
        this.unbindCropper()
      }

      this.replaceThumbnails(res.data)
    }).catch((error) => {
      console.error('Failed to save crop', error)
      trigger?.removeAttribute('disabled')
      this.stateValue = previousState
      this.subscribePreviewCandidates()
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
    this.unsubscribePreviewCandidates()
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
      this.bindSelectionSaveShortcut()
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

  bindSelectionSaveShortcut () {
    this.selectionDoubleClickHandler = (event) => this.saveEditing(event)
    this.cropperSelection.addEventListener('dblclick', this.selectionDoubleClickHandler)
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

  replaceThumbnails ({ main, details }) {
    const show = this.element.closest('.f-c-files-show')
    const currentMain = show?.querySelector('.f-c-files-show-thumbnails-main')
    const currentDetails = show?.querySelector('.f-c-files-show-thumbnails-details')
    const replacementMain = this.componentFromHtml(main)
    const replacementDetails = this.componentFromHtml(details)

    if (!currentMain || !currentDetails || !replacementMain || !replacementDetails) return

    const expanded = currentMain.dataset.fCFilesShowThumbnailsMainExpandedValue === 'true'
    replacementMain.dataset.fCFilesShowThumbnailsMainExpandedValue = expanded
    replacementDetails.hidden = !expanded

    currentMain.replaceWith(replacementMain)
    currentDetails.replaceWith(replacementDetails)
  }

  componentFromHtml (html) {
    const template = document.createElement('template')
    template.innerHTML = html.trim()

    return template.content.firstElementChild
  }

  openOverlay () {
    if (!this.overlayTarget.open) {
      this.overlayTarget.showModal()
      document.activeElement?.blur()
      this.bindKeyboardSaveShortcut()
    }
  }

  closeOverlay () {
    this.unbindKeyboardSaveShortcut()
    if (this.overlayTarget.open) this.overlayTarget.close()
  }

  bindKeyboardSaveShortcut () {
    this.keydownHandler = (event) => {
      if (event.key === 'Escape') {
        event.preventDefault()
        event.stopImmediatePropagation()
        this.cancelEditing()
      } else if (event.key === 'Enter') {
        this.saveEditing(event)
      }
    }

    document.addEventListener('keydown', this.keydownHandler, true)
  }

  unbindKeyboardSaveShortcut () {
    if (!this.keydownHandler) return

    document.removeEventListener('keydown', this.keydownHandler, true)
    this.keydownHandler = null
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
    if (this.cropperSelection && this.selectionDoubleClickHandler) {
      this.cropperSelection.removeEventListener('dblclick', this.selectionDoubleClickHandler)
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
    this.selectionDoubleClickHandler = null
    this.initializationTimeout = null
    this.initializationFrame = null
  }

  clamp (value, minimum, maximum) {
    return Math.min(Math.max(value, minimum), Math.max(minimum, maximum))
  }

  thumbnailUpdated (event) {
    if (!this.hasPreviewCandidatesValue) {
      if (this.stateValue === 'waiting-for-thumbnail') this.stateValue = 'viewing'
      return
    }

    const candidate = this.previewCandidatesValue.find(({ size }) => size === event.detail.size)

    if (!candidate) return

    if (!event.detail.url || candidate.priority >= this.previewPriorityValue || !this.hasThumbImageTarget) return

    this.thumbImageTarget.src = event.detail.url
    this.thumbImageTarget.hidden = false
    this.previewPriorityValue = candidate.priority
    if (this.stateValue !== 'saving') this.stateValue = 'viewing'
    this.subscribePreviewCandidates()
  }

  beginPreviewGeneration (crop) {
    if (!this.hasPreviewCandidatesValue || !this.hasFileIdValue) return

    this.unsubscribePreviewCandidates()
    window.FolioConsole.FilesShowThumbnailPreviews.beginGeneration({
      element: this.element,
      fileId: this.fileIdValue,
      candidates: this.previewCandidatesValue,
      crop
    })
    this.previewCandidatesSubscribed = true
  }

  subscribePreviewCandidates () {
    this.unsubscribePreviewCandidates()

    if (!this.hasPreviewCandidatesValue || !this.hasFileIdValue) return

    const candidates = this.previewCandidatesValue.filter(({ pending, priority }) => {
      return pending && priority < this.previewPriorityValue
    })
    if (!candidates.length) return

    const completed = window.FolioConsole.FilesShowThumbnailPreviews.subscribe({
      element: this.element,
      fileId: this.fileIdValue,
      candidates,
      crop: this.hasPreviewCropValue ? this.previewCropValue : null
    })
    this.previewCandidatesSubscribed = true

    for (const detail of completed) this.thumbnailUpdated({ detail })
  }

  unsubscribePreviewCandidates () {
    if (!this.previewCandidatesSubscribed) return

    window.FolioConsole.FilesShowThumbnailPreviews.unsubscribe({ element: this.element })
    this.previewCandidatesSubscribed = false
  }
})
