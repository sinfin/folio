//= require folio/remote_scripts

window.Folio.Stimulus.register('f-nested-fields', class extends window.Stimulus.Controller {
  static values = {
    key: String,
    sortableBound: Boolean
  }

  static targets = ['template', 'fieldsWrap', 'destroyedWrap', 'fields', 'sortableHandle']

  connect () {
    this.fieldsTargets.forEach((fieldsTarget) => {
      if (fieldsTarget.hidden) {
        this.destroyedWrapTarget.appendChild(fieldsTarget)
      }
    })

    this.redoPositions()
  }

  disconnect () {
    if (this.debouncedSortableInit) {
      delete this.debouncedSortableInit
    }

    this.stopAutoScroll()

    if (this.sortableBound) {
      if (window.sortable) {
        window.sortable(this.fieldsWrapTarget, 'destroy')
      }

      if (this.onSortStart) {
        this.fieldsWrapTarget.removeEventListener('sortstart', this.onSortStart)
        delete this.onSortStart
      }

      if (this.onSortStop) {
        this.fieldsWrapTarget.removeEventListener('sortstop', this.onSortStop)
        delete this.onSortStop
      }

      this.sortableBound = false
    }
  }

  onAddClick (e) {
    e.preventDefault()
    this.add()
  }

  add () {
    this.fieldsWrapTarget.insertAdjacentHTML('beforeend', this.htmlFromTemplate())
    this.redoPositions()
    this.dispatchRequiredEvents('added', { field: this.fieldsTargets[this.fieldsTargets.length - 1] })
  }

  dispatchRequiredEvents (name, data = {}) {
    const count = this.fieldsWrapTarget.querySelectorAll('.f-nested-fields__fields').length
    const detail = { ...data, count }

    this.dispatch(name, { detail })
    this.element.dispatchEvent(new CustomEvent(`f-nested-fields:${name}`, { detail, bubbles: true }))
  }

  nodeFromTemplate () {
    const html = this.htmlFromTemplate()
    const element = document.createElement('div')
    element.innerHTML = html
    return element.firstChild
  }

  htmlFromTemplate () {
    const html = this.templateTarget.innerHTML

    let rxp = new RegExp(`\\[f-nested-fields-template-${this.keyValue}\\]`, 'g')

    this.newIds = this.newIds || []
    let newId = new Date().getTime()

    while (this.newIds.includes(newId)) {
      newId += 1
    }

    this.newIds.push(newId)

    let newHtml = html.replace(rxp, `[${newId}]`)

    if (newHtml === html) {
      rxp = new RegExp(`\\[f-nested-fields-template-${this.keyValue}s\\]`, 'g')
      newHtml = html.replace(rxp, '[' + newId + ']')
    }

    return newHtml
  }

  onDestroyClick (e) {
    e.preventDefault()

    window.Folio.Confirm.confirm(() => {
      const fields = e.target.closest('.f-nested-fields__fields')
      this.destroyFields(fields)
    }, 'remove')
  }

  destroyFields (fields) {
    const idInput = fields.querySelector('.f-nested-fields__id-input')

    if (idInput && idInput.value) {
      const destroyInput = fields.querySelector('.f-nested-fields__destroy-input')

      destroyInput.value = '1'
      fields.hidden = true
      this.destroyedWrapTarget.appendChild(fields)
    } else {
      fields.remove()
    }

    this.redoPositions()
    this.dispatchRequiredEvents('destroyed')
  }

  onPositionUpClick (e) {
    e.preventDefault()
    const fields = e.target.closest('.f-nested-fields__fields')
    const target = fields.previousElementSibling

    if (target && target.classList.contains('f-nested-fields__fields')) {
      target.insertAdjacentElement('beforebegin', fields)
      this.redoPositions()
    }
  }

  onPositionDownClick (e) {
    e.preventDefault()
    const fields = e.target.closest('.f-nested-fields__fields')
    const target = fields.nextElementSibling

    if (target && target.classList.contains('f-nested-fields__fields')) {
      target.insertAdjacentElement('afterend', fields)
      this.redoPositions()
    }
  }

  redoPositions () {
    let position = 0
    let triggeredChange = false

    this.fieldsTargets.forEach((fields) => {
      if (!fields.hidden) {
        const input = fields.querySelector('.f-nested-fields__position-input')

        if (input) {
          position += 1

          if (input.value !== String(position)) {
            input.value = position

            if (!triggeredChange) {
              input.dispatchEvent(new Event('change', { bubbles: true }))
              triggeredChange = true
            }
          }
        }
      }
    })
  }

  sortableHandleTargetConnected (element) {
    if (!this.debouncedSortableInit) this.debouncedSortableInit = window.Folio.debounce(this.initSortable)
    this.debouncedSortableInit()
  }

  sortableHandleTargetDisconnected (element) {
    if (!this.debouncedSortableInit) this.debouncedSortableInit = window.Folio.debounce(this.initSortable)
    this.debouncedSortableInit()
  }

  sortableHandleSelector () {
    if (this.element.classList.contains('f-nested-fields--fully-draggable')) {
      return '.f-nested-fields__sortable-backdrop'
    } else {
      return '.f-nested-fields__control--sortable-handle'
    }
  }

  initSortable () {
    window.Folio.RemoteScripts.run('html5sortable', () => {
      if (this.sortableBound) {
        window.sortable(this.fieldsWrapTarget)
      } else {
        window.sortable(this.fieldsWrapTarget, {
          items: '.f-nested-fields__fields',
          handle: this.sortableHandleSelector(),
          placeholder: '<div class="f-nested-fields__sortable-placeholder"><div class="f-nested-fields__sortable-placeholder-inner"></div></div>'
        })

        this.onSortStart = (e) => {
          if (window.FolioConsole && window.FolioConsole.Autosave) {
            window.FolioConsole.Autosave.pause({ target: this.element })
          }
          this.startAutoScroll()
        }

        this.onSortStop = (e) => {
          if (window.FolioConsole && window.FolioConsole.Autosave) {
            window.FolioConsole.Autosave.resume({ target: this.element })
          }
          this.stopAutoScroll()
        }

        this.fieldsWrapTarget.addEventListener('sortstart', this.onSortStart)
        this.fieldsWrapTarget.addEventListener('sortstop', this.onSortStop)

        this.sortableBound = true
      }
    }, () => {
      this.element.classList.add('f-nested-fields--sortable-broken')
    })
  }

  startAutoScroll () {
    this.stopAutoScroll()

    const baseScrollSpeed = 3
    const maxScrollSpeed = 15
    const scrollSensitivity = 50
    let rafId = null
    let lastMouseY = null
    let edgeTime = 0
    const accelerationRate = 0.015
    const maxAcceleration = 1.3

    // Detect and cache scroll container once when dragging starts
    const getScrollableContainer = () => {
      let element = this.fieldsWrapTarget
      while (element && element !== document.body && element !== document.documentElement) {
        const style = window.getComputedStyle(element)
        const overflowY = style.overflowY || style.overflow
        if (overflowY === 'auto' || overflowY === 'scroll') {
          const scrollHeight = element.scrollHeight
          const clientHeight = element.clientHeight
          if (scrollHeight > clientHeight) {
            return element
          }
        }
        element = element.parentElement
      }
      return null
    }

    // Cache scroll container for the duration of this drag operation
    const scrollContainer = getScrollableContainer()
    const isWindowScroll = !scrollContainer

    // Cache container rect - invalidate on window resize
    let cachedRect = null
    let rectCacheFrame = 0
    let cachedRectWindowWidth = window.innerWidth
    let cachedRectWindowHeight = window.innerHeight
    const RECT_CACHE_FRAMES = 3 // Recalculate rect every 3 frames (~50ms)

    const updateMousePosition = (e) => {
      if (e && e.clientY !== undefined) {
        lastMouseY = e.clientY
      }
    }

    const calculateScrollSpeed = (distanceFromEdge) => {
      const distanceFactor = 1 - (distanceFromEdge / scrollSensitivity)
      const distanceSpeed = baseScrollSpeed + (maxScrollSpeed - baseScrollSpeed) * (distanceFactor * distanceFactor)
      const timeMultiplier = 1 + Math.min(edgeTime * accelerationRate, maxAcceleration - 1)
      return distanceSpeed * timeMultiplier
    }

    const performAutoScroll = () => {
      if (lastMouseY === null) {
        edgeTime = 0
        rafId = window.requestAnimationFrame(performAutoScroll)
        return
      }

      const mouseY = lastMouseY
      let scrollDelta = 0
      let distanceFromEdge = 0

      if (isWindowScroll) {
        const viewportHeight = window.innerHeight

        // Early exit if not near edges
        if (mouseY >= scrollSensitivity && mouseY <= viewportHeight - scrollSensitivity) {
          edgeTime = 0
          rafId = window.requestAnimationFrame(performAutoScroll)
          return
        }

        if (mouseY < scrollSensitivity) {
          distanceFromEdge = mouseY
          scrollDelta = -calculateScrollSpeed(distanceFromEdge)
          edgeTime += 1
        } else {
          distanceFromEdge = viewportHeight - mouseY
          scrollDelta = calculateScrollSpeed(distanceFromEdge)
          edgeTime += 1
        }

        if (scrollDelta !== 0) {
          const currentScroll = window.pageYOffset || document.documentElement.scrollTop

          // Only calculate maxScroll when needed (cached per frame)
          const maxScroll = Math.max(
            document.body.scrollHeight,
            document.documentElement.scrollHeight
          ) - viewportHeight

          if ((scrollDelta < 0 && currentScroll > 0) || (scrollDelta > 0 && currentScroll < maxScroll)) {
            window.scrollBy(0, scrollDelta)
          }
        }
      } else {
        // Cache getBoundingClientRect() - expensive operation
        // Invalidate cache if window size changed
        const currentWidth = window.innerWidth
        const currentHeight = window.innerHeight
        const needsRectRecalc = !cachedRect ||
                                rectCacheFrame === 0 ||
                                cachedRectWindowWidth !== currentWidth ||
                                cachedRectWindowHeight !== currentHeight

        if (needsRectRecalc) {
          cachedRect = scrollContainer.getBoundingClientRect()
          cachedRectWindowWidth = currentWidth
          cachedRectWindowHeight = currentHeight
          rectCacheFrame = RECT_CACHE_FRAMES
        } else {
          rectCacheFrame--
        }

        const containerTop = cachedRect.top
        const containerHeight = cachedRect.bottom - containerTop
        const relativeY = mouseY - containerTop

        // Early exit if not near edges
        if (relativeY >= scrollSensitivity && relativeY <= containerHeight - scrollSensitivity) {
          edgeTime = 0
          cachedRect = null // Clear cache when not scrolling
          rafId = window.requestAnimationFrame(performAutoScroll)
          return
        }

        if (relativeY < scrollSensitivity) {
          distanceFromEdge = relativeY
          scrollDelta = -calculateScrollSpeed(distanceFromEdge)
          edgeTime += 1
        } else {
          distanceFromEdge = containerHeight - relativeY
          scrollDelta = calculateScrollSpeed(distanceFromEdge)
          edgeTime += 1
        }

        if (scrollDelta !== 0) {
          const currentScroll = scrollContainer.scrollTop
          const maxScroll = scrollContainer.scrollHeight - scrollContainer.clientHeight

          if ((scrollDelta < 0 && currentScroll > 0) || (scrollDelta > 0 && currentScroll < maxScroll)) {
            scrollContainer.scrollTop += scrollDelta
          }
        }
      }

      rafId = window.requestAnimationFrame(performAutoScroll)
    }

    const onMouseMove = (e) => updateMousePosition(e)
    const onDragOver = (e) => updateMousePosition(e)
    const onDrag = (e) => updateMousePosition(e)

    document.addEventListener('mousemove', onMouseMove, { passive: true, capture: true })
    document.addEventListener('dragover', onDragOver, { passive: true, capture: true })
    document.addEventListener('drag', onDrag, { passive: true, capture: true })
    this.fieldsWrapTarget.addEventListener('dragover', onDragOver, { passive: true, capture: true })
    this.fieldsWrapTarget.addEventListener('drag', onDrag, { passive: true, capture: true })

    rafId = window.requestAnimationFrame(performAutoScroll)

    this.autoScrollCleanup = () => {
      document.removeEventListener('mousemove', onMouseMove, { capture: true })
      document.removeEventListener('dragover', onDragOver, { capture: true })
      document.removeEventListener('drag', onDrag, { capture: true })
      this.fieldsWrapTarget.removeEventListener('dragover', onDragOver, { capture: true })
      this.fieldsWrapTarget.removeEventListener('drag', onDrag, { capture: true })
      if (rafId !== null) {
        window.cancelAnimationFrame(rafId)
        rafId = null
      }
      lastMouseY = null
      cachedRect = null
    }
  }

  stopAutoScroll () {
    if (this.autoScrollCleanup) {
      this.autoScrollCleanup()
      delete this.autoScrollCleanup
    }
  }

  onSortUpdate (e) {
    this.redoPositions()
  }

  onAddMultipleWithAttributesTrigger (e) {
    if (!e || !e.detail || !e.detail.attributesCollection || e.detail.attributesCollection.length < 1) throw new Error('Invalid event data - missing attributes')

    e.detail.attributesCollection.forEach((attributes) => {
      const node = this.nodeFromTemplate()

      Object.keys(attributes).forEach((key) => {
        node.setAttribute(key, attributes[key])
      })

      this.fieldsWrapTarget.insertAdjacentElement('beforeend', node)
    })

    this.redoPositions()
    this.dispatchRequiredEvents('added', { field: this.fieldsTargets[this.fieldsTargets.length - 1] })
  }

  onRemoveFieldsTrigger (e) {
    if (!e || !e.target) return
    const fields = e.target.closest('.f-nested-fields__fields')

    if (!fields) return
    this.destroyFields(fields)
  }
})
