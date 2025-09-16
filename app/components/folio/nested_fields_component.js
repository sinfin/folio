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
    this.dispatch('add', { detail: { field: this.fieldsTargets[this.fieldsTargets.length - 1] } })
    this.element.dispatchEvent(new CustomEvent('f-nested-fields:add', { bubbles: true }))
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
    const newId = new Date().getTime()
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
      this.dispatch('destroyed')
      this.element.dispatchEvent(new CustomEvent('f-nested-fields:destroyed', { bubbles: true }))
    }, 'remove')
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

  initSortable () {
    window.Folio.RemoteScripts.run('html5sortable', () => {
      if (this.sortableBound) {
        window.sortable(this.fieldsWrapTarget)
      } else {
        window.sortable(this.fieldsWrapTarget, {
          items: '.f-nested-fields__fields',
          handle: '.f-nested-fields__control--sortable-handle',
          placeholder: '<div class="f-nested-fields__sortable-placeholder"><div class="f-nested-fields__sortable-placeholder-inner"></div></div>'
        })

        if (window.FolioConsole && window.FolioConsole.Autosave) {
          this.onSortStart = (e) => { window.FolioConsole.Autosave.pause() }
          this.onSortStop = (e) => { window.FolioConsole.Autosave.resume() }

          this.fieldsWrapTarget.addEventListener('sortstart', this.onSortStart)
          this.fieldsWrapTarget.addEventListener('sortstop', this.onSortStop)
        }

        this.sortableBound = true
      }
    }, () => {
      this.element.classList.add('f-nested-fields--sortable-broken')
    })
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
    this.dispatch('add', { detail: { field: this.fieldsTargets[this.fieldsTargets.length - 1] } })
    this.element.dispatchEvent(new CustomEvent('f-nested-fields:add', { bubbles: true }))
  }
})
