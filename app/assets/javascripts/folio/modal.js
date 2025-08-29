window.Folio = window.Folio || {}
window.Folio.Modal = window.Folio.Modal || {}

window.Folio.Modal.open = (modal) => {
  modal.dataset.fModalOpenValue = 'true'
  return true
}

window.Folio.Modal.close = (modal) => {
  modal.dataset.fModalOpenValue = 'false'
  return true
}

window.Folio.Stimulus.register('f-modal', class extends window.Stimulus.Controller {
  static values = {
    open: { type: Boolean, default: false }
  }

  disconnect () {
    this.unbindOutsideClick()
    this.removeBackdrop()
    delete this.toggleElement
  }

  onToggleClick (e) {
    if (this.openValue) {
      this.openValue = false
      delete this.toggleElement
    } else {
      this.openValue = true
      this.toggleElement = e.detail.toggle

      if (e && e.detail && e.detail.dialog) {
        const dialogs = this.element.querySelectorAll('.modal-dialog')

        for (const dialog of dialogs) {
          dialog.classList.remove('modal-dialog--active')
        }

        const dialog = this.element.querySelector(e.detail.dialog)
        dialog.classList.add('modal-dialog--active')
      }
    }
  }

  onAnyClick (e) {
    if (e.target === this.element) {
      this.openValue = false
    }
  }

  bindOutsideClick () {
    this.unbindOutsideClick()

    this.boundOnAnyClick = this.onAnyClick.bind(this)
    this.element.addEventListener('click', this.boundOnAnyClick)
  }

  unbindOutsideClick () {
    if (this.boundOnAnyClick) {
      this.element.removeEventListener('click', this.boundOnAnyClick)
      delete this.boundOnAnyClick
    }
  }

  addBackdrop () {
    const backdrop = document.createElement('div')
    backdrop.className = 'modal-backdrop show'
    backdrop.dataset.controller = 'f-modal-close'
    backdrop.dataset.action = 'click->f-modal-close#click'

    document.body.appendChild(backdrop)

    this.backdropElement = backdrop
  }

  removeBackdrop () {
    if (this.backdropElement) {
      this.backdropElement.remove()
      delete this.backdropElement
    }
  }

  openValueChanged (value, from) {
    if (!value && !from) return

    if (value) {
      this.bindOutsideClick()

      document.documentElement.classList.add('modal-open')
      document.body.classList.add('modal-open')

      this.element.classList.add('show')
      this.element.style.display = 'block'

      this.addBackdrop()

      const autofocus = this.element.querySelector('[autofocus]')
      if (autofocus) {
        autofocus.focus()
      }

      this.dispatch('opened')
      this.element.dispatchEvent(new window.CustomEvent('f-modal:opened', { bubbles: true }))

      if (this.toggleElement) {
        this.toggleElement.dispatchEvent(new window.CustomEvent('f-modal-toggle:opened', { bubbles: true }))
      }
    } else {
      this.unbindOutsideClick()

      document.documentElement.classList.remove('modal-open')
      document.body.classList.remove('modal-open')

      this.element.classList.remove('show')
      this.element.style.display = 'none'

      this.removeBackdrop()

      this.dispatch('closed')
      this.element.dispatchEvent(new window.CustomEvent('f-modal:closed', { bubbles: true }))

      if (this.toggleElement) {
        this.toggleElement.dispatchEvent(new window.CustomEvent('f-modal-toggle:closed', { bubbles: true }))
      }
    }
  }
})

window.Folio.Stimulus.register('f-modal-toggle', class extends window.Stimulus.Controller {
  static values = {
    target: String,
    dialog: String
  }

  click (e) {
    e.preventDefault()
    const modal = document.querySelector(this.targetValue)

    if (!modal) {
      throw new Error(`No modal for selector "${this.targetValue}" found.`)
    }

    modal.dispatchEvent(new window.CustomEvent('f-modal-toggle:toggle', { bubbles: true, detail: { toggle: this.element, dialog: this.dialogValue } }))
  }
})

window.Folio.Stimulus.register('f-modal-close', class extends window.Stimulus.Controller {
  static values = {
    target: { type: String, default: '' }
  }

  click (e) {
    e.preventDefault()

    if (this.targetValue) {
      const modal = document.querySelector(this.targetValue)

      if (!modal) {
        throw new Error(`No modal for selector "${this.targetValue}" found.`)
      }

      window.Folio.Modal.close(modal)
    } else {
      const modals = document.querySelectorAll('[data-f-modal-open-value="true"]')

      for (const modal of modals) {
        window.Folio.Modal.close(modal)
      }
    }
  }
})
