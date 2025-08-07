window.Folio.Stimulus.register('f-c-files-subtitles-form', class extends window.Stimulus.Controller {
  static targets = ["loader", "languagesContainer", "addLanguageForm"]

  static values = {
    fileId: Number,
    reloadUrl: String,
    retranscribeUrl: String
  }

  connect() {
    this.setupMessageBusListener()
    this.addedLanguages = new Set()
    this.initializeAddedLanguages()
    this.updateAddLanguageOptions()
    this.initializeAccordionState()
  }

  disconnect() {
    this.abortAjax()
    this.cleanupMessageBusListener()
    this.cleanupAccordionListeners()
  }

  abortAjax() {
    if (!this.abortController) return
    this.abortController.abort()
    delete this.abortController
  }

  ajax({ url, data, apiMethod = 'apiGet' }) {
    this.abortAjax()
    this.abortController = new AbortController()
    this.showLoader()

    return window.Folio.Api[apiMethod](url, data, this.abortController.signal).then((res) => {
      if (res && res.data) {
        if (this.element && this.element.parentNode) {
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

  showLoader() {
    if (this.hasLoaderTarget) {
      this.loaderTarget.hidden = false
    }
  }

  hideLoader() {
    if (this.hasLoaderTarget) {
      this.loaderTarget.hidden = true
    }
  }

  retranscribe(e) {
    e.preventDefault()
    
    this.ajax({
      url: this.retranscribeUrlValue,
      apiMethod: "apiPost"
    })
  }

  reloadPlayer() {
    window.location.reload()
  }

  // Handle events from child subtitle form components
  subtitleDeleted(e) {
    const language = e.detail.language
    this.addedLanguages.delete(language)
    this.updateAddLanguageOptions()
  }

  newSubtitleRemoved(e) {
    const language = e.detail.language
    this.addedLanguages.delete(language)
    this.updateAddLanguageOptions()
  }

  addLanguage(e) {
    e.preventDefault()
    
    if (!this.hasAddLanguageFormTarget) {
      console.error('Add language form not found')
      return
    }
    
    const select = this.addLanguageFormTarget.querySelector('select')
    const language = select?.value
    
    if (!language || language === '') {
      window.alert(window.FolioConsole.translations.pleaseSelectLanguage)
      return
    }
    
    if (this.addedLanguages.has(language)) {
      window.alert(window.FolioConsole.translations.languageAlreadyAdded)
      return
    }
    
    // Get the new subtitle form component HTML from server
    const url = `/console/api/file/videos/${this.fileIdValue}/subtitles/${language}/new.json`
    
    this.showLoader()
    
    window.Folio.Api.apiGet(url).then((res) => {
      if (res && res.data) {
        // Add the new component to the languages container
        if (this.hasLanguagesContainerTarget) {
          this.languagesContainerTarget.insertAdjacentHTML('beforeend', res.data)
          
          // Track this language as added
          this.addedLanguages.add(language)
          
          // Reset the form and update options
          this.addLanguageFormTarget.reset()
          this.updateAddLanguageOptions()
          
          // Reinitialize accordion state for the newly added language
          setTimeout(() => {
            this.cleanupAccordionListeners()
            this.setupAccordionListeners()
            // Auto-open the newly added language accordion and save state
            this.openAccordionForLanguage(language)
            this.saveAccordionState(language, true)
          }, 100)
        }
              } else {
          window.alert(window.FolioConsole.translations.failedToAddLanguage)
        }
      }).catch((e) => {
        window.alert(window.FolioConsole.translations.errorGeneric.replace('%{message}', e.message))
      }).finally(() => {
      this.hideLoader()
    })
  }

  initializeAddedLanguages() {
    // Track existing persisted subtitles
    if (this.hasLanguagesContainerTarget) {
      const existingComponents = this.languagesContainerTarget.querySelectorAll('[data-controller*="f-c-files-subtitle-form"]')
      existingComponents.forEach(component => {
        const languageValue = component.getAttribute('data-f-c-files-subtitle-form-language-value')
        if (languageValue) {
          this.addedLanguages.add(languageValue)
        }
      })
    }
  }

  updateAddLanguageOptions() {
    if (!this.hasAddLanguageFormTarget) return
    
    const select = this.addLanguageFormTarget.querySelector('select')
    if (!select) return
    
    let availableOptionsCount = 0
    
    // Hide options for languages that have been added and count available options
    Array.from(select.options).forEach(option => {
      if (option.value === '') {
        // Skip the prompt option
        return
      }
      
      if (option.value && this.addedLanguages.has(option.value)) {
        option.style.display = 'none'
      } else {
        option.style.display = 'block'
        availableOptionsCount++
      }
    })
    
    // Hide the entire add language section if no languages are available
    const addLanguageSection = this.addLanguageFormTarget.closest('.f-c-files-subtitles-form__add-language')
    if (addLanguageSection) {
      if (availableOptionsCount === 0) {
        addLanguageSection.style.display = 'none'
      } else {
        addLanguageSection.style.display = 'block'
      }
    }
  }

  initializeAccordionState() {
    // Wait for DOM to be ready
    setTimeout(() => {
      this.setupAccordionListeners()
      this.restoreAccordionState()
    }, 100)
  }

  setupAccordionListeners() {
    if (!this.hasLanguagesContainerTarget) return

    this.accordionListeners = []

    const accordionElements = this.languagesContainerTarget.querySelectorAll('.accordion-collapse')
    accordionElements.forEach(element => {
      const showListener = () => {
        const language = this.getLanguageFromAccordionElement(element)
        if (language) {
          this.saveAccordionState(language, true)
        }
      }

      const hideListener = () => {
        const language = this.getLanguageFromAccordionElement(element)
        if (language) {
          this.saveAccordionState(language, false)
        }
      }

      element.addEventListener('shown.bs.collapse', showListener)
      element.addEventListener('hidden.bs.collapse', hideListener)

      this.accordionListeners.push({
        element: element,
        showListener: showListener,
        hideListener: hideListener
      })
    })
  }

  cleanupAccordionListeners() {
    if (this.accordionListeners) {
      this.accordionListeners.forEach(({ element, showListener, hideListener }) => {
        element.removeEventListener('shown.bs.collapse', showListener)
        element.removeEventListener('hidden.bs.collapse', hideListener)
      })
      this.accordionListeners = []
    }
  }

  getLanguageFromAccordionElement(element) {
    const subtitleFormElement = element.closest('[data-controller*="f-c-files-subtitle-form"]')
    if (subtitleFormElement) {
      return subtitleFormElement.getAttribute('data-f-c-files-subtitle-form-language-value')
    }
    return null
  }

  getAccordionStorageKey() {
    return `subtitles-accordion-state-${this.fileIdValue}`
  }

  saveAccordionState(language, isOpen) {
    try {
      const storageKey = this.getAccordionStorageKey()
      const currentState = JSON.parse(sessionStorage.getItem(storageKey) || '{}')
      
      if (isOpen) {
        currentState[language] = true
      } else {
        delete currentState[language]
      }
      
      sessionStorage.setItem(storageKey, JSON.stringify(currentState))
    } catch (error) {
      console.warn('Failed to save accordion state:', error)
    }
  }

  restoreAccordionState() {
    try {
      const storageKey = this.getAccordionStorageKey()
      const savedState = JSON.parse(sessionStorage.getItem(storageKey) || '{}')
      
      Object.keys(savedState).forEach(language => {
        if (savedState[language]) {
          this.openAccordionForLanguage(language)
        }
      })
    } catch (error) {
      console.warn('Failed to restore accordion state:', error)
    }
  }

  openAccordionForLanguage(language) {
    if (!this.hasLanguagesContainerTarget) return

    const subtitleFormElement = this.languagesContainerTarget.querySelector(`[data-f-c-files-subtitle-form-language-value="${language}"]`)
    if (subtitleFormElement) {
      const accordionCollapse = subtitleFormElement.querySelector('.accordion-collapse')
      const accordionButton = subtitleFormElement.querySelector('.accordion-button')
      
      if (accordionCollapse && accordionButton) {
        // Use Bootstrap's collapse API to open the accordion
        const collapseInstance = new bootstrap.Collapse(accordionCollapse, {
          show: true
        })
        
        // Update button state
        accordionButton.classList.remove('collapsed')
        accordionButton.setAttribute('aria-expanded', 'true')
      }
    }
  }

  reload() {
    this.ajax({
      url: this.reloadUrlValue
    }).then(() => {
      // Reinitialize accordion state after reload
      this.initializeAccordionState()
    })
  }

  buildPayload(formData) {
    const payload = {}
    
    for (let [key, value] of formData.entries()) {
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

  setupMessageBusListener() {
    if (!window.Folio.MessageBus.callbacks) return

    this.messageBusCallbackKey = `f-c-files-subtitles-form--${this.fileIdValue}`

    window.Folio.MessageBus.callbacks[this.messageBusCallbackKey] = (message) => {
      if (!message) return

      // Listen for subtitle-specific updates from transcription jobs
      if ((message.type === 'Folio::ElevenLabs::TranscribeSubtitlesJob/updated' ||
           message.type === 'Folio::OpenAi::TranscribeSubtitlesJob/updated') &&
          message.data && Number(message.data.id) === Number(this.fileIdValue)) {
        
        // Reload the component to show updated subtitle status
        this.reload()
      }
    }
  }

  cleanupMessageBusListener() {
    if (this.messageBusCallbackKey && window.Folio.MessageBus.callbacks) {
      delete window.Folio.MessageBus.callbacks[this.messageBusCallbackKey]
    }
  }
}) 