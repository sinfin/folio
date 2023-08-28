window.Folio.Stimulus.register('f-modal', class extends window.Stimulus.Controller {
  static values = {
    open: Boolean
  }

  disconnect () {
    this.unbindOutsideClick()
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
  }

  removeBackdrops () {
    const backdrops = document.querySelectorAll('.modal-backdrop')
    for (const backdrop of backdrops) {
      backdrop.parentNode.removeChild(backdrop)
    }
  }

  openValueChanged (value) {
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
    } else {
      this.unbindOutsideClick()

      document.documentElement.classList.remove('modal-open')
      document.body.classList.remove('modal-open')

      this.element.classList.remove('show')
      this.element.style.display = 'none'

      this.removeBackdrops()
    }
  }
})

window.Folio.Stimulus.register('f-modal-toggle', class extends window.Stimulus.Controller {
  static values = {
    target: String,
    dialog: String,
  }

  click (e) {
    e.preventDefault()
    const modal = document.querySelector(this.targetValue)

    if (!modal) {
      throw new Error(`No modal for selector "${this.targetValue}" found.`)
    }

    if (modal.dataset.fModalOpenValue === 'true') {
      modal.dataset.fModalOpenValue = 'false'
    } else {
      modal.dataset.fModalOpenValue = 'true'

      if (this.dialogValue) {
        const dialogs = modal.querySelectorAll('.modal-dialog')

        for (const dialog of dialogs) {
          dialog.classList.remove('modal-dialog--active')
        }

        const dialog = modal.querySelector(this.dialogValue)
        dialog.classList.add('modal-dialog--active')
      }
    }
  }
})

window.Folio.Stimulus.register('f-modal-close', class extends window.Stimulus.Controller {
  click (e) {
    e.preventDefault()
    const modals = $('[data-f-modal-open-value="true"]')

    for (const modal of modals) {
      modal.dataset.fModalOpenValue = 'false'
    }
  }
})
