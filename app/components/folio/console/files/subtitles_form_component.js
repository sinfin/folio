window.Folio.Stimulus.register('f-c-files-subtitles-form', class extends window.Stimulus.Controller {
  static targets = ["loader"]

  static values = {
    fileId: Number,
    reloadUrl: String,
    retranscribeAllUrl: String
  }

  connect() {
    this.setupMessageBusListener()
  }

  disconnect() {
    this.abortAjax()
    this.cleanupMessageBusListener()
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
        window.alert('Invalid server response')
      }
    }).catch((e) => {
      if (e.name !== 'AbortError') {
        window.alert('Error: ' + e.message)
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

  retranscribeAll(e) {
    e.preventDefault()
    
    this.ajax({
      url: this.retranscribeAllUrlValue,
      apiMethod: "apiPost"
    })
  }

  onSubtitleFormSubmit(e) {
    e.preventDefault()
    
    const form = e.target
    const language = e.params.language
    
    if (!language) {
      window.alert('Language parameter missing')
      return
    }
    
    const formData = new FormData(form)
    const payload = this.buildPayload(formData)
    
    this.ajax({
      url: form.action,
      apiMethod: form.method.toLowerCase() === 'patch' ? 'apiPatch' : 'apiPost',
      data: payload
    })
  }

  addLanguage(e) {
    e.preventDefault()
    
    const form = e.target.closest('form')
    if (!form) {
      console.error('Form not found')
      return
    }
    
    const select = form.querySelector('select')
    const language = select?.value
    
    if (!language || language === '') {
      window.alert('Please select a language')
      return
    }
    
    const baseUrl = this.reloadUrlValue.replace('/subtitles_html.json', '/subtitles/')
    const url = baseUrl + language + '.json'
    
    const formData = new FormData(form)
    const payload = this.buildPayload(formData)
    
    this.ajax({
      url: url,
      apiMethod: "apiPost",
      data: payload
    })
  }

  deleteSubtitle(e) {
    e.preventDefault()
    
    const language = e.params.language
    if (!language) {
      window.alert('Language parameter missing')
      return
    }
    
    window.Folio.Confirm.message(() => {
      const url = `${this.reloadUrlValue.replace('/subtitles_html.json', '')}/subtitles/${language}.json`
      
      this.ajax({
        url: url,
        apiMethod: "apiDelete"
      })
    }, 'Opravdu?')
  }

  cancelForm(e) {
    e.preventDefault()
    this.reload()
  }

  reload() {
    this.ajax({
      url: this.reloadUrlValue
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