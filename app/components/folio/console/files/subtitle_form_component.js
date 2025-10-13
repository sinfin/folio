window.Folio.Stimulus.register('f-c-files-subtitle-form', class extends window.Stimulus.Controller {
  static targets = ['loader']

  static values = {
    language: String,
    fileId: Number,
    persisted: Boolean
  }

  connect () {
    this.setupMessageBusListener()
    this.initializeAccordionState()
  }

  disconnect () {
    this.abortAjax()
    this.cleanupMessageBusListener()
    this.cleanupAccordionListeners()
  }

  abortAjax () {
    if (!this.abortController) return
    this.abortController.abort()
    delete this.abortController
  }

  ajax ({ url, data, apiMethod = 'apiGet' }) {
    this.abortAjax()
    this.abortController = new AbortController()
    this.showLoader()

    return window.Folio.Api[apiMethod](url, data, this.abortController.signal).then((res) => {
      if (res && res.data) {
        if (this.element && this.element.parentNode) {
          // Replace only this component
          this.element.outerHTML = res.data
        }
      } else {
        window.alert(window.FolioConsole.translations.invalidServerResponse)
      }
    }).catch((e) => {
      if (e.name !== 'AbortError') {
        window.alert(window.FolioConsole.translations.errorGeneric.replace('%{message}', e.message))
      }
    }).finally(() => {
      this.hideLoader()
      delete this.abortController
    })
  }

  showLoader () {
    if (this.hasLoaderTarget) {
      this.loaderTarget.hidden = false
    }
  }

  hideLoader () {
    if (this.hasLoaderTarget) {
      this.loaderTarget.hidden = true
    }
  }

  onFormSubmit (e) {
    e.preventDefault()

    const form = e.target
    const formData = new FormData(form)
    const payload = this.buildPayload(formData)

    this.ajax({
      url: form.action,
      apiMethod: form.method.toLowerCase() === 'patch' ? 'apiPatch' : 'apiPost',
      data: payload
    }).then(() => {
      // Reinitialize accordion state after form submission
      this.initializeAccordionState()
    })
  }

  deleteSubtitle (e) {
    e.preventDefault()

    if (!this.persistedValue) {
      console.error('Cannot delete non-persisted subtitle')
      return
    }

    window.Folio.Confirm.message(() => {
      const url = `/console/api/file/videos/${this.fileIdValue}/subtitles/${this.languageValue}.json`

      this.showLoader()

      window.Folio.Api.apiDelete(url).then(() => {
        // Clean up accordion state for this language
        this.cleanupAccordionStateForLanguage(this.languageValue)

        // Capture parent root before removing this element so we can reload it
        const parentRoot = this.element.closest('.f-c-files-subtitles-form')
        const parentLoader = parentRoot ? parentRoot.querySelector('.f-c-files-subtitles-form__loader') : null

        this.dispatch('subtitleDeleted', {
          detail: { language: this.languageValue },
          bubbles: true
        })

        if (this.element && this.element.parentNode) {
          this.element.remove()
        }

        this.reloadEntireSubtitlesForm(parentRoot, parentLoader)
      }).catch((e) => {
        window.alert(window.FolioConsole.translations.errorGeneric.replace('%{message}', e.message))
      }).finally(() => {
        this.hideLoader()
      })
    }, window.FolioConsole.translations.deleteSubtitleConfirm)
  }

  removeNewSubtitle (e) {
    e.preventDefault()

    if (this.persistedValue) {
      console.error('Cannot remove persisted subtitle')
      return
    }

    // Clean up accordion state for this language
    this.cleanupAccordionStateForLanguage(this.languageValue)

    this.dispatch('newSubtitleRemoved', {
      detail: { language: this.languageValue },
      bubbles: true
    })

    if (this.element && this.element.parentNode) {
      this.element.remove()
    }
  }

  cancelForm (e) {
    e.preventDefault()

    if (!this.persistedValue) {
      // For new subtitles, just remove them
      this.removeNewSubtitle(e)
      return
    }

    // For existing subtitles, reload to cancel changes
    this.reload()
  }

  initializeAccordionState () {
    // Wait for DOM to be ready
    setTimeout(() => {
      this.setupAccordionListeners()
      this.restoreAccordionState()
    }, 100)
  }

  setupAccordionListeners () {
    const accordionElement = this.element.querySelector('.accordion-collapse')
    if (!accordionElement) return

    this.accordionShowListener = () => {
      this.saveAccordionState(true)
    }

    this.accordionHideListener = () => {
      this.saveAccordionState(false)
    }

    accordionElement.addEventListener('shown.bs.collapse', this.accordionShowListener)
    accordionElement.addEventListener('hidden.bs.collapse', this.accordionHideListener)
  }

  cleanupAccordionListeners () {
    const accordionElement = this.element.querySelector('.accordion-collapse')
    if (accordionElement && this.accordionShowListener && this.accordionHideListener) {
      accordionElement.removeEventListener('shown.bs.collapse', this.accordionShowListener)
      accordionElement.removeEventListener('hidden.bs.collapse', this.accordionHideListener)
    }
  }

  getAccordionStorageKey () {
    return `subtitles-accordion-state-${this.fileIdValue}`
  }

  saveAccordionState (isOpen) {
    try {
      const storageKey = this.getAccordionStorageKey()
      const currentState = JSON.parse(window.sessionStorage.getItem(storageKey) || '{}')

      if (isOpen) {
        currentState[this.languageValue] = true
      } else {
        delete currentState[this.languageValue]
      }

      window.sessionStorage.setItem(storageKey, JSON.stringify(currentState))
    } catch (error) {
      console.warn('Failed to save accordion state:', error)
    }
  }

  restoreAccordionState () {
    try {
      const storageKey = this.getAccordionStorageKey()
      const savedState = JSON.parse(window.sessionStorage.getItem(storageKey) || '{}')

      if (savedState[this.languageValue]) {
        this.openAccordion()
      }
    } catch (error) {
      console.warn('Failed to restore accordion state:', error)
    }
  }

  openAccordion () {
    const accordionCollapse = this.element.querySelector('.accordion-collapse')
    const accordionButton = this.element.querySelector('.accordion-button')

    if (accordionCollapse && accordionButton) {
      // Use Bootstrap's collapse API to open the accordion
      const collapseInstance = new window.bootstrap.Collapse(accordionCollapse, {
        show: true
      })
      console.log('TODO: cleanup collapseInstance on disconnect', collapseInstance)

      // Update button state
      accordionButton.classList.remove('collapsed')
      accordionButton.setAttribute('aria-expanded', 'true')
    }
  }

  reload () {
    const url = `/console/api/file/videos/${this.fileIdValue}/subtitles/${this.languageValue}/html.json`

    this.ajax({
      url
    }).then(() => {
      // Reinitialize accordion state after reload
      this.initializeAccordionState()
    })
  }

  reloadEntireSubtitlesForm (providedRoot = null, providedLoader = null) {
    if (!this.subtitlesReloadUrlValue) return

    const target = providedRoot || this.element

    this.dispatch('reload', {
      detail: { url: this.subtitlesReloadUrlValue },
      target,
      bubbles: true
    })
  }

  buildPayload (formData) {
    const payload = {}

    for (const [key, value] of formData.entries()) {
      if (key.includes('[') && key.includes(']')) {
        const matches = key.match(/^([^[]+)\[([^\]]+)\]$/)
        if (matches) {
          const [, parentKey, childKey] = matches
          if (!payload[parentKey]) {
            payload[parentKey] = {}
          }
          if (childKey === 'enabled') {
            payload[parentKey][childKey] = value === '1' || value === 'true'
          } else {
            payload[parentKey][childKey] = value
          }
        }
      } else {
        payload[key] = value
      }
    }

    return payload
  }

  setupMessageBusListener () {
    if (!window.Folio.MessageBus.callbacks) return

    this.messageBusCallbackKey = `f-c-files-subtitle-form--${this.fileIdValue}--${this.languageValue}`

    window.Folio.MessageBus.callbacks[this.messageBusCallbackKey] = (message) => {
      if (!message) return

      // Listen for subtitle-specific updates from transcription jobs
      if ((message.type === 'Folio::ElevenLabs::TranscribeSubtitlesJob/updated' ||
           message.type === 'Folio::OpenAi::TranscribeSubtitlesJob/updated') &&
          message.data &&
          Number(message.data.id) === Number(this.fileIdValue) &&
          message.data.language === this.languageValue) {
        // Reload only this subtitle component
        this.reload()
      }
    }
  }

  cleanupMessageBusListener () {
    if (this.messageBusCallbackKey && window.Folio.MessageBus.callbacks) {
      delete window.Folio.MessageBus.callbacks[this.messageBusCallbackKey]
    }
  }

  cleanupAccordionStateForLanguage (language) {
    try {
      const storageKey = this.getAccordionStorageKey()
      const currentState = JSON.parse(window.sessionStorage.getItem(storageKey) || '{}')

      delete currentState[language]
      window.sessionStorage.setItem(storageKey, JSON.stringify(currentState))
    } catch (error) {
      console.warn('Failed to cleanup accordion state:', error)
    }
  }
})
