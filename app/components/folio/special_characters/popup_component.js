window.Folio.Stimulus.register('f-special-characters-popup', class extends window.Stimulus.Controller {
  connect () {
    this.isDragging = false
    this.wasMoved = false
    this.lastCoords = { x: 0, y: 0 }
    this.left = 0
    this.top = 0

    this.onDocumentMousemove = this.onDocumentMousemove.bind(this)
    this.onDocumentMouseup = this.onDocumentMouseup.bind(this)
    this.onDocumentTouchmove = this.onDocumentTouchmove.bind(this)
    this.onDocumentTouchend = this.onDocumentTouchend.bind(this)
  }

  disconnect () {
    this.stopDragging()
  }

  get isOpen () {
    return !this.element.inert
  }

  toggle (e) {
    if (this.isOpen) {
      this.close()
    } else {
      this.open(e?.target)
    }
  }

  open (triggerEl) {
    if (!this.wasMoved) {
      if (triggerEl instanceof window.Element) {
        this.positionAboveTrigger(triggerEl)
      } else {
        this.centerPanel()
      }
    }
    this.applyPosition()
    this.element.inert = false
  }

  positionAboveTrigger (triggerEl) {
    const rect = this.element.getBoundingClientRect()
    const triggerRect = triggerEl.getBoundingClientRect()
    const gap = 8
    this.left = Math.round(triggerRect.left + triggerRect.width / 2 - rect.width / 2)
    this.top = Math.round(triggerRect.top - rect.height - gap)
  }

  close () {
    this.element.inert = true
    this.stopDragging()
  }

  centerPanel () {
    const rect = this.element.getBoundingClientRect()
    const vw = window.innerWidth
    const vh = window.innerHeight
    this.left = Math.round((vw - rect.width) / 2)
    this.top = Math.round((vh - rect.height) / 2)
  }

  applyPosition () {
    this.moveTo(this.left, this.top)
  }

  moveTo (left, top) {
    const rect = this.element.getBoundingClientRect()
    const vw = window.innerWidth
    const vh = window.innerHeight

    if (left + rect.width > vw) {
      left = vw - rect.width
    }
    if (left < 0) {
      left = 0
    }
    if (top + rect.height > vh) {
      top = vh - rect.height
    }
    if (top < 0) {
      top = 0
    }

    this.left = left
    this.top = top
    this.element.style.left = `${this.left}px`
    this.element.style.top = `${this.top}px`
  }

  moveBy (dx, dy) {
    this.moveTo(this.left + dx, this.top + dy)
  }

  insertCharacter (e) {
    const char = e.currentTarget?.dataset?.char
    if (!char) return

    const target = document.activeElement
    if (!target || this.element.contains(target)) return

    if (target.matches('input, textarea')) {
      const type = (target.type || '').toLowerCase()
      if (type === 'checkbox' || type === 'radio' || type === 'hidden' || type === 'file') {
        return
      }
      const start = typeof target.selectionStart === 'number' ? target.selectionStart : 0
      const end = typeof target.selectionEnd === 'number' ? target.selectionEnd : start
      if (typeof target.setRangeText === 'function') {
        target.setRangeText(char, start, end, 'end')
      } else {
        target.value = target.value.slice(0, start) + char + target.value.slice(end)
      }
      target.dispatchEvent(new window.Event('input', { bubbles: true }))
      target.dispatchEvent(new window.Event('change', { bubbles: true }))
      return
    }

    if (target.matches('.f-input-tiptap__iframe')) {
      target.dispatchEvent(new CustomEvent('f-special-characters-popup:insertText', {
        bubbles: true,
        detail: { text: char }
      }))
    }
  }

  preventDefault (e) {
    e.preventDefault()
  }

  onDragHandleMousedown (e) {
    if (!e.target || e.target.nodeType !== 1) return
    if (e.target.closest('.f-special-characters-popup__close')) return
    if (e.button !== 0) return
    this.startDrag(e.clientX, e.clientY)
    e.preventDefault()
  }

  onDragHandleTouchstart (e) {
    if (!e.target || e.target.nodeType !== 1) return
    if (e.target.closest('.f-special-characters-popup__close')) return
    const touch = e.touches[0]
    if (!touch) return
    this.startDrag(touch.clientX, touch.clientY)
  }

  startDrag (x, y) {
    this.isDragging = true
    this.wasMoved = true
    this.lastCoords = { x, y }
    this.element.classList.add('f-special-characters-popup--dragging')
    document.addEventListener('mousemove', this.onDocumentMousemove)
    document.addEventListener('mouseup', this.onDocumentMouseup)
    document.addEventListener('touchmove', this.onDocumentTouchmove, { passive: false })
    document.addEventListener('touchend', this.onDocumentTouchend)
  }

  stopDragging () {
    if (!this.isDragging) return
    this.isDragging = false
    this.element.classList.remove('f-special-characters-popup--dragging')
    document.removeEventListener('mousemove', this.onDocumentMousemove)
    document.removeEventListener('mouseup', this.onDocumentMouseup)
    document.removeEventListener('touchmove', this.onDocumentTouchmove)
    document.removeEventListener('touchend', this.onDocumentTouchend)
  }

  onDocumentMousemove (e) {
    if (!this.isDragging) return
    e.preventDefault()
    this.dragTo(e.clientX, e.clientY)
  }

  onDocumentTouchmove (e) {
    if (!this.isDragging) return
    const touch = e.touches[0]
    if (!touch) return
    e.preventDefault()
    this.dragTo(touch.clientX, touch.clientY)
  }

  dragTo (x, y) {
    const dx = Math.round(x - this.lastCoords.x)
    const dy = Math.round(y - this.lastCoords.y)
    this.moveBy(dx, dy)
    this.lastCoords = { x, y }
  }

  onDocumentMouseup () {
    this.stopDragging()
  }

  onDocumentTouchend () {
    this.stopDragging()
  }
})
