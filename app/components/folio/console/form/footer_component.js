window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.Autosave = window.FolioConsole.Autosave || {}
window.FolioConsole.Autosave.TIMER_SECONDS = 3

window.Folio.Stimulus.register('f-c-form-footer', class extends window.Stimulus.Controller {
  static values = {
    status: String,
    collapsed: Boolean,
    settings: Boolean,
    autosaveEnabled: Boolean,
    autosaveTimer: { type: Number, default: -1 },
  }

  static targets = ["autosaveInput"]

  disconnect () {
    this.unbindUnload()
    this.clearAutosaveTimeout()
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
    this.element.closest('form').classList.toggle('f-c-form-footer-form-saving',
                                                  this.statusValue === 'saving')

    if (this.statusValue === 'unsaved') {
      this.bindUnload()
    } else {
      this.unbindUnload()
    }
  }

  queueAutosaveIfPossible () {
    if (this.autosaveEnabledValue && window.FolioConsole.Autosave.enabled) {
      this.autosaveTimerValue = window.FolioConsole.Autosave.TIMER_SECONDS
    }
  }

  onWindowMessage (e) {
    if (e.origin === window.origin && e.data.type === 'setFormAsDirty') {
      this.statusValue = 'unsaved'
      this.queueAutosaveIfPossible()
    }
  }

  isFromProperForm (e) {
    const form = this.element.closest('form')
    const targetForm = e.target.closest('form')
    return form === targetForm
  }

  onDocumentChange (e) {
    if (!this.isFromProperForm(e)) return

    this.statusValue = 'unsaved'

    if (e.detail && e.detail.redactor) return

    if (this.shouldAbortBasedOnTarget(document.activeElement)) {
      return
    }

    this.queueAutosaveIfPossible()
  }

  resumeAutosaveIfNeeded () {
    if (this.statusValue !== 'unsaved') return
    this.queueAutosaveIfPossible()
}

  onDocumentFocusout (e) {
    if (!this.autosaveEnabledValue || !window.FolioConsole.Autosave.enabled) return
    this.resumeAutosaveIfNeeded()
  }

  onDocumentAtomsFormHidden (e) {
    if (!this.autosaveEnabledValue || !window.FolioConsole.Autosave.enabled) return
    this.resumeAutosaveIfNeeded()
  }

  onDocumentAtomsFormShown (e) {
    if (!this.autosaveEnabledValue || !window.FolioConsole.Autosave.enabled) return
    if (!this.isFromProperForm(e)) return

    if (this.autosaveTimerValue !== -1) {
      this.autosaveTimerValue = -1
    }
  }

  abortAutosave () {
    this.clearAutosaveTimeout()

    if (this.autosaveTimerValue !== -1) {
      this.autosaveTimerValue = -1
    }
  }

  shouldAbortBasedOnTarget (target) {
    const tagName = target.tagName

    if (tagName === 'INPUT') return true
    if (tagName === 'TEXTAREA') return true
    if (tagName === 'SELECT') return true

    if (target.classList.contains('redactor-in')) return true

    return false
  }

  onDocumentFocusin (e) {
    if (!this.autosaveEnabledValue || !window.FolioConsole.Autosave.enabled) return
    if (!this.isFromProperForm(e)) return

    if (this.shouldAbortBasedOnTarget(e.target)) {
      this.abortAutosave()
    }
  }

  onDocumentSubmit (e) {
    if (!this.isFromProperForm(e)) return
    this.statusValue = 'saving'
  }

  toggleSettings (e) {
    e.preventDefault()
    this.settingsValue = !this.settingsValue
  }

  toggleCollapsed (e) {
    e.preventDefault()
    this.collapsedValue = !this.collapsedValue
  }

  clearAutosaveTimeout () {
    if (this.autosaveTimeout) {
      window.clearTimeout(this.autosaveTimeout)
      delete this.autosaveTimeout
    }
  }

  autosaveTimerValueChanged (to, from) {
    this.clearAutosaveTimeout()

    if (!this.autosaveEnabledValue || !window.FolioConsole.Autosave.enabled) {
      this.autosaveTimerValue = -1
      return
    }

    if (from === to) return

    if (to === 0) {
      this.element.closest('form').requestSubmit()
    } else if (to > 0) {
      this.autosaveTimeout = window.setTimeout(() => {
        this.autosaveTimerValue = to - 1
      }, 1000)
    }
  }

  reloadPage () {
    this.statusValue = 'saving'
    window.location.reload()
  }

  reloadPageWhenPossible () {
    if (this.statusValue === 'saved') {
      this.reloadPage()
    } else if (this.statusValue === 'unsaved') {
      if (this.autosaveEnabledValue && window.FolioConsole.Autosave.enabled) {
        this.queueAutosaveIfPossible()
      } else {
        this.element.closest('form').requestSubmit()
      }
    }
  }

  onNestedFieldsAdd (e) {
    if (!this.autosaveEnabledValue || !window.FolioConsole.Autosave.enabled) return
    if (!this.isFromProperForm(e)) return

    this.abortAutosave()
  }

  onDocumentSortstart (e) {
    if (!this.autosaveEnabledValue || !window.FolioConsole.Autosave.enabled) return
    if (!this.isFromProperForm(e)) return

    this.abortAutosave()
  }

  onDocumentSortstop (e) {
    if (!this.autosaveEnabledValue || !window.FolioConsole.Autosave.enabled) return
    if (!this.isFromProperForm(e)) return

    this.resumeAutosaveIfNeeded()
  }
})
