window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.Autosave = window.FolioConsole.Autosave || {}
window.FolioConsole.Autosave.TIMER_SECONDS = 3

window.FolioConsole.Autosave.enabledChangeCallback = () => {
  if (window.FolioConsole.Autosave.enabled) {
    window.FolioConsole.Autosave.resume()
  } else {
    window.FolioConsole.Autosave.pause()
  }
}

window.FolioConsole.Autosave.resume = () => {
  const footer = document.querySelector('.f-c-form-footer')
  if (!footer) return
  footer.dispatchEvent(new CustomEvent('f-c-form-footer:resumeAutosave', { bubbles: true }))
}

window.FolioConsole.Autosave.pause = () => {
  const footer = document.querySelector('.f-c-form-footer')
  if (!footer) return
  footer.dispatchEvent(new CustomEvent('f-c-form-footer:pauseAutosave', { bubbles: true }))
}

window.Folio.Stimulus.register('f-c-form-footer', class extends window.Stimulus.Controller {
  static values = {
    status: String,
    collapsed: Boolean,
    settings: Boolean,
    autosaveEnabled: Boolean,
    autosavePaused: { type: Boolean, default: false },
    autosaveTimer: { type: Number, default: -1 }
  }

  static targets = ['autosaveInput', 'submitButton', 'submitButtonIndicator']

  connect () {
    this.restoreUiState()
  }

  disconnect () {
    this.unbindUnload()
    this.clearAutosaveTimeout()
    delete this.lastTargetCache
  }

  bindUnload () {
    if (this.onBeforeUnload) return

    this.onBeforeUnload = (e) => {
      e.preventDefault()
      e.returnValue = 'Changes you made may not be saved.'
      return 'Changes you made may not be saved.'
    }
    window.addEventListener('beforeunload', this.onBeforeUnload)
  }

  unbindUnload () {
    if (this.onBeforeUnload) {
      window.removeEventListener('beforeunload', this.onBeforeUnload)
      delete this.onBeforeUnload
    }
  }

  statusValueChanged () {
    const saving = this.statusValue === 'saving'

    this.element.closest('form').classList.toggle('f-c-form-footer-form-saving', saving)

    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = saving
    }

    if (this.statusValue === 'unsaved') {
      this.bindUnload()
    } else {
      this.unbindUnload()
    }
  }

  queueAutosaveIfPossible (target) {
    if (!this.autosaveEnabledValue || !window.FolioConsole.Autosave.enabled) return
    if (this.autosavePausedValue) return
    if (this.atomsFormOpen()) return
    if (this.anyModalOpen()) return
    if (target && this.lastTargetCache && target === this.lastTargetCache && this.autosaveTimerValue > 0 && target.type !== 'checkbox') return
    if (document.activeElement) {
      if (document.activeElement.tagName === 'TEXTAREA') return
      if (document.activeElement.tagName === 'INPUT') {
        if (document.activeElement.type !== 'radio' && document.activeElement.type !== 'checkbox') return
      }
    }

    this.lastTargetCache = target

    if (this.autosaveEnabledValue && window.FolioConsole.Autosave.enabled) {
      this.autosaveTimerValue = 10 * window.FolioConsole.Autosave.TIMER_SECONDS
    }
  }

  atomsFormOpen () {
    return !!document.querySelector('.f-c-simple-form-with-atoms--editing-atom')
  }

  anyModalOpen () {
    return !!document.querySelector('.f-c-ui-modal.show')
  }

  onWindowMessage (e) {
    if (this.atomsFormOpen()) return
    if (this.anyModalOpen()) return

    if (e.origin === window.origin) {
      switch (e.data.type) {
        case 'setFormAsDirty':
          this.statusValue = 'unsaved'
          this.queueAutosaveIfPossible()
          break
        case 'atomsInsertShown':
          this.pauseAutosave()
          break
        case 'atomsInsertHidden':
          this.resumeAutosave()
          break
      }
    }
  }

  isFromProperForm (e) {
    const form = this.element.closest('form')
    const targetForm = e.target.closest('form')
    return form === targetForm
  }

  onDocumentInput (e) {
    if (!this.isFromProperForm(e)) return

    if (e && e.target && e.target.tagName === 'SELECT') {
      this.pauseAutosave()
      this.resumeAutosave()
    }
  }

  onDocumentChange (e) {
    if (!this.isFromProperForm(e)) return

    this.statusValue = 'unsaved'

    if (e.detail && e.detail.redactor) return

    if (this.shouldAbortBasedOnElement({ element: document.activeElement, target: e.target })) {
      return
    }

    this.queueAutosaveIfPossible(e.target)
  }

  resumeAutosave (element) {
    if (this.statusValue !== 'unsaved') return
    this.queueAutosaveIfPossible(element)
  }

  onResumeAutosave () {
    this.resumeAutosave()
  }

  onDocumentFocusout (e) {
    if (!this.autosaveEnabledValue || !window.FolioConsole.Autosave.enabled) return
    this.resumeAutosave(e.target)
  }

  onDocumentAtomsFormHidden (e) {
    if (!this.autosaveEnabledValue || !window.FolioConsole.Autosave.enabled) return
    this.resumeAutosave(e.target)
  }

  onDocumentAtomsFormShown (e) {
    if (!this.autosaveEnabledValue || !window.FolioConsole.Autosave.enabled) return
    if (!this.isFromProperForm(e)) return

    if (this.autosaveTimerValue !== -1) {
      this.autosaveTimerValue = -1
    }
  }

  pauseAutosave () {
    this.clearAutosaveTimeout()

    if (this.autosaveTimerValue !== -1) {
      this.autosaveTimerValue = -1
    }
  }

  onPauseAutosave () {
    this.pauseAutosave()
  }

  shouldAbortBasedOnElement ({ element, target }) {
    const tagName = element.tagName

    if (tagName === 'INPUT') {
      if (target && element.type === 'radio' && target === element) return false
      if (target && element.type === 'checkbox' && target === element) return false
      return true
    }

    if (tagName === 'TEXTAREA') return true
    if (tagName === 'SELECT' && element !== target) return true

    if (element.classList.contains('redactor-in')) return true

    return false
  }

  onDocumentFocusin (e) {
    if (!this.autosaveEnabledValue || !window.FolioConsole.Autosave.enabled) return
    if (!this.isFromProperForm(e)) return

    if (this.shouldAbortBasedOnElement({ element: e.target })) {
      this.pauseAutosave()
    }
  }

  onDocumentSubmit (e) {
    if (!this.isFromProperForm(e)) return

    if (this.statusValue === 'saving') {
      e.preventDefault()
      return
    }

    this.storeUiState()
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
      this.submitButtonIndicatorTarget.style.transform = 'scaleX(0)'
      return
    }

    if (from === to) return

    if (to === -1) {
      this.submitButtonIndicatorTarget.style.transform = 'scaleX(0)'
      return
    }

    // shift by one so that the transition ends at the same time as the submit
    const remaining = 10 * window.FolioConsole.Autosave.TIMER_SECONDS - (to - 1)
    // handle the shift - don't overflow 1
    const width = Math.min(1, remaining / (10 * window.FolioConsole.Autosave.TIMER_SECONDS) * 1)
    const scale = Math.round(100 * width) / 100

    this.submitButtonIndicatorTarget.style.transform = `scaleX(${scale})`

    if (to === 0) {
      if (this.statusValue !== 'saving') this.element.closest('form').requestSubmit()
    } else if (to > 0) {
      this.autosaveTimeout = window.setTimeout(() => {
        this.autosaveTimerValue = to - 1
      }, 100)
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
        if (this.statusValue !== 'saving') this.element.closest('form').requestSubmit()
      }
    }
  }

  onDocumentBsTabShown () {
    if (this.statusValue !== 'unsaved') return
    this.queueAutosaveIfPossible()
  }

  storeUiState () {
    const atomsForm = document.querySelector('.f-c-simple-form-with-atoms__form-scroll')
    const atomsPreviews = document.querySelector('.f-c-simple-form-with-atoms__iframe')
    const flash = document.querySelector('.f-c-flash-wrap')
    const flashOffset = flash ? flash.offsetHeight : 0

    const data = {
      window: window.scrollY - flashOffset,
      now: Date.now()
    }

    if (atomsForm) data.form = atomsForm.scrollTop

    if (atomsPreviews) {
      data.previewsHeight = atomsPreviews.clientHeight
      data.previewsScroll = atomsPreviews.contentWindow.scrollY
    }

    if (document.querySelector('.f-c-simple-form-with-atoms--expanded-form')) data.atomsFormExpanded = true

    window.sessionStorage.setItem('fCAutosaveUiState', JSON.stringify(data))
  }

  restoreUiState () {
    if (!window.FolioConsole.Autosave.restoreUiState) return
    window.FolioConsole.Autosave.restoreUiState({ clear: true })
  }

  onNestedFieldsAdd () {
    this.pauseAutosave()
  }

  onNestedFieldsDestroyed () {
    this.queueAutosaveIfPossible()
  }

  onModalOpened () {
    this.pauseAutosave()
  }

  onModalClosed () {
    this.queueAutosaveIfPossible()
  }

  autosavePausedValueChanged (to, from) {
    if (to === from) return

    if (this.autosavePausedValue) {
      this.pauseAutosave()
    } else {
      this.resumeAutosave()
    }
  }

  onSelect2Open () {
    this.autosavePausedValue = true
  }

  onSelect2Close () {
    this.autosavePausedValue = false
  }
})
