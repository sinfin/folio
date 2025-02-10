window.Folio.Stimulus.register('f-c-form-footer', class extends window.Stimulus.Controller {
  static values = {
    status: String,
  }

  disconnect () {
    this.unbindUnload()
  }

  bindUnload () {
    if (this.onBeforeUnload) return

    this.onBeforeUnload = (e) => {
      e.preventDefault()
      e.returnValue = 'Changes you made may not be saved.'
      return 'Changes you made may not be saved.'
    }
  }

  unbindUnload () {
    if (this.onBeforeUnload) {
      window.removeEventListener('beforeunload', this.onBeforeUnload)
      delete this.onBeforeUnload
    }
  }

  statusValueChanged () {
    if (this.statusValue === 'unsaved') {
      this.bindUnload()
    } else {
      this.unbindUnload()
    }
  }

  onWindowMessage (e) {
    if (e.origin === window.origin && e.data.type === 'setFormAsDirty') {
      this.statusValue = 'unsaved'
    }
  }

  onDocumentChange (e) {
    const form = e.target.closest('form')
    const targetForm = e.target.closest('form')

    if (form === targetForm) {
      this.statusValue = 'unsaved'
    }
  }

  onDocumentSubmit (e) {
    const form = e.target.closest('form')
    const targetForm = e.target.closest('form')

    if (form === targetForm) {
      this.statusValue = 'saving'
    }
  }
})
