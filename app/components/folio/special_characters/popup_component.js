window.Folio.Stimulus.register('f-special-characters-popup', class extends window.Stimulus.Controller {
  connect () {
    this.isDragging = false
    this.wasMoved = false
    this.lastCoords = { x: 0, y: 0 }
    this.left = 0
    this.top = 0
    this.lastInputEl = null
    this.lastTiptapWrap = null

    this.onDocumentMousemove = this.onDocumentMousemove.bind(this)
    this.onDocumentMouseup = this.onDocumentMouseup.bind(this)
    this.onDocumentTouchmove = this.onDocumentTouchmove.bind(this)
    this.onDocumentTouchend = this.onDocumentTouchend.bind(this)
  }

  disconnect () {
    this.stopDragging()
  }

  get isOpen () {
    return this.element.classList.contains('f-special-characters-popup--visible')
  }

  toggle () {
    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open () {
    if (!this.wasMoved) {
      this.centerPanel()
    }
    this.applyPosition()
    this.element.classList.add('f-special-characters-popup--visible')
  }

  close () {
    this.element.classList.remove('f-special-characters-popup--visible')
    this.stopDragging()
  }

  onWindowKeydown (e) {
    if (e.key === 'Escape' && this.isOpen) {
      this.close()
    }
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

    if (left + rect.width > vw) {
      left = vw - rect.width
    }
    if (left < 0) {
      left = 0
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

  onDocumentFocusin (e) {
    const t = e.target
    if (!t || t.nodeType !== 1) return
    if (this.element.contains(t)) return

    if (t.matches('input, textarea')) {
      const type = (t.type || '').toLowerCase()
      if (type === 'checkbox' || type === 'radio' || type === 'hidden' || type === 'file') {
        return
      }
      this.lastInputEl = t
      this.lastTiptapWrap = null
      return
    }

    if (t.matches('iframe.f-input-tiptap__iframe')) {
      const wrap = t.closest('.f-input-tiptap')
      if (wrap) {
        this.lastTiptapWrap = wrap
        this.lastInputEl = null
      }
      return
    }

    const wrap = t.closest('.f-input-tiptap')
    if (wrap) {
      this.lastTiptapWrap = wrap
      this.lastInputEl = null
    }
  }

  insertCharacter (e) {
    const char = e.currentTarget?.dataset?.char
    if (!char) return

    if (this.lastInputEl && document.body.contains(this.lastInputEl)) {
      const el = this.lastInputEl
      const start = typeof el.selectionStart === 'number' ? el.selectionStart : 0
      const end = typeof el.selectionEnd === 'number' ? el.selectionEnd : start
      if (typeof el.setRangeText === 'function') {
        el.setRangeText(char, start, end, 'end')
      } else {
        el.value = el.value.slice(0, start) + char + el.value.slice(end)
      }
      el.dispatchEvent(new window.Event('input', { bubbles: true }))
      el.dispatchEvent(new window.Event('change', { bubbles: true }))
      return
    }

    if (this.lastTiptapWrap && document.body.contains(this.lastTiptapWrap)) {
      const iframe = this.lastTiptapWrap.querySelector('iframe.f-input-tiptap__iframe')
      if (iframe && iframe.contentWindow) {
        iframe.contentWindow.postMessage(
          { type: 'f-input-tiptap:insert-text', text: char },
          window.origin
        )
      }
    }
  }

  onCharMousedown (e) {
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
