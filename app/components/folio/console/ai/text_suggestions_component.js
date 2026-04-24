window.Folio.Stimulus.register('f-c-ai-text-suggestions', class extends window.Stimulus.Controller {
  static targets = [
    'button',
    'undoButton',
    'panel',
    'status',
    'suggestions',
    'instructions'
  ]

  static values = {
    endpoint: String,
    integrationKey: String,
    fieldKey: String,
    targetSelector: String,
    suggestionCount: { type: Number, default: 3 },
    characterLimit: Number,
    initialInstructions: { type: String, default: '' },
    loadingText: String,
    genericErrorText: String,
    missingContextText: String,
    copyLabel: String,
    acceptLabel: String,
    charsLabel: String
  }

  static classes = ['open', 'loading']

  connect () {
    this.snapshot = null
    this.selectedText = null
    this.requestSequence = 0
    this.savedInstructions = this.initialInstructionsValue
    this.targetInputListener = () => this.onTargetInput()
    this.targetInput?.addEventListener('input', this.targetInputListener)
  }

  disconnect () {
    this.abortRequest()
    this.targetInput?.removeEventListener('input', this.targetInputListener)
  }

  toggle (event) {
    event.preventDefault()
    event.stopPropagation()

    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open () {
    const input = this.targetInput

    if (!input) {
      this.showPanel()
      this.showError(this.genericErrorTextValue)
      return
    }

    document.dispatchEvent(new CustomEvent('folio:ai-text-suggestions:open', {
      bubbles: true,
      detail: { controller: this }
    }))

    this.snapshot = input.value || ''
    this.selectedText = null
    this.clearSelection()
    this.showPanel()
    this.generate({ persistInstructions: false })
  }

  close (event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    this.abortRequest()
    this.snapshot = null
    this.selectedText = null
    this.panelTarget.hidden = true
    this.undoButtonTarget.hidden = true
    this.suggestionsTarget.innerHTML = ''
    this.hideStatus()
    this.element.classList.remove(this.openClass)
    this.element.classList.remove(this.loadingClass)
    this.buttonTarget.setAttribute('aria-expanded', 'false')
    this.instructionsTarget.value = this.savedInstructions
  }

  regenerate (event) {
    event.preventDefault()
    event.stopPropagation()

    if (!this.isOpen) this.showPanel()

    this.generate({ persistInstructions: true })
  }

  undo (event) {
    event.preventDefault()
    event.stopPropagation()

    if (this.snapshot === null) return

    const input = this.targetInput
    if (!input) return

    this.writeValue(input, this.snapshot)
    this.selectedText = null
    this.clearSelection()
    this.undoButtonTarget.hidden = true

    this.dispatch('undo', { detail: this.trackingDetail() })
  }

  accept (event) {
    event.preventDefault()
    event.stopPropagation()

    const input = this.targetInput
    if (!input) return

    const text = event.params.text || ''
    this.selectedText = text
    this.writeValue(input, text)
    this.markSelected(event.currentTarget)
    this.undoButtonTarget.hidden = false

    this.dispatch('accepted', { detail: this.trackingDetail() })
  }

  copy (event) {
    event.preventDefault()
    event.stopPropagation()

    const text = event.params.text || ''

    this.copyText(text).then(() => {
      this.dispatch('copied', { detail: this.trackingDetail() })
    })
  }

  onTargetInput () {
    if (!this.selectedText) return
    if (!this.targetInput || this.targetInput.value === this.selectedText) return

    this.selectedText = null
    this.clearSelection()
  }

  onWindowClick (event) {
    if (!this.isOpen) return
    if (this.element.contains(event.target)) return

    this.close()
  }

  onWindowKeydown (event) {
    if (!this.isOpen) return
    if (event.key !== 'Escape') return

    this.close()
  }

  onOtherPanelOpen (event) {
    if (!this.isOpen) return
    if (event.detail?.controller === this) return

    this.close()
  }

  stopPropagation (event) {
    event.stopPropagation()
  }

  generate ({ persistInstructions }) {
    const requestId = this.nextRequestId()
    this.abortRequest()
    this.abortController = new AbortController()
    this.setLoading()

    window.Folio.Api.apiPost(this.endpointValue, this.requestPayload(persistInstructions), this.abortController.signal)
      .then((response) => {
        if (this.staleRequest(requestId)) return

        this.handleSuccess(response, { persistInstructions })
      })
      .catch((error) => {
        if (this.staleRequest(requestId) || error.name === 'AbortError') return

        this.handleError(error)
      })
      .finally(() => {
        if (this.staleRequest(requestId)) return

        this.element.classList.remove(this.loadingClass)
      })
  }

  requestPayload (persistInstructions) {
    return {
      integration_key: this.integrationKeyValue,
      field_key: this.fieldKeyValue,
      instructions: this.instructionsTarget.value,
      persist_instructions: persistInstructions,
      suggestion_count: this.suggestionCountValue
    }
  }

  handleSuccess (response, { persistInstructions }) {
    const data = response.data || response
    const suggestions = data.suggestions || []

    if (typeof data.user_instructions !== 'undefined') {
      this.instructionsTarget.value = data.user_instructions || ''

      if (persistInstructions) {
        this.savedInstructions = this.instructionsTarget.value
      }
    }

    if (suggestions.length === 0) {
      this.showError(this.genericErrorTextValue)
      return
    }

    this.hideStatus()
    this.renderSuggestions(suggestions)
  }

  handleError (error) {
    this.suggestionsTarget.innerHTML = ''
    this.showError(this.errorMessage(error))
  }

  errorMessage (error) {
    const responseData = error.responseData || {}
    const code = responseData.error_code || responseData.code || responseData.error
    const detail = responseData.message || this.errorDetail(responseData)

    if (['missing_context', 'record_not_ready', 'host_ineligible'].includes(code)) {
      return detail || this.missingContextTextValue
    }

    return detail || this.genericErrorTextValue
  }

  errorDetail (responseData) {
    if (!responseData.errors || responseData.errors.length === 0) return null

    return responseData.errors[0].detail || responseData.errors[0].title
  }

  renderSuggestions (suggestions) {
    this.suggestionsTarget.innerHTML = ''

    suggestions.forEach((suggestion) => {
      this.suggestionsTarget.appendChild(this.suggestionElement(suggestion))
    })
  }

  suggestionElement (suggestion) {
    const button = document.createElement('button')
    button.type = 'button'
    button.className = 'f-c-ai-text-suggestions__suggestion'
    button.setAttribute('data-action', 'click->f-c-ai-text-suggestions#accept')
    button.setAttribute('data-f-c-ai-text-suggestions-text-param', suggestion.text || '')
    button.setAttribute('data-f-c-ai-text-suggestions-key-param', suggestion.key || '')

    const body = document.createElement('span')
    body.className = 'f-c-ai-text-suggestions__suggestion-body'
    body.appendChild(this.suggestionMetaElement(suggestion))
    body.appendChild(this.suggestionTextElement(suggestion.text || ''))

    const actions = document.createElement('span')
    actions.className = 'f-c-ai-text-suggestions__suggestion-actions'
    actions.appendChild(this.actionButton('copy', this.copyLabelValue, suggestion.text || ''))
    actions.appendChild(this.actionButton('accept', this.acceptLabelValue, suggestion.text || ''))

    button.appendChild(body)
    button.appendChild(actions)

    return button
  }

  suggestionMetaElement (suggestion) {
    const meta = document.createElement('span')
    meta.className = 'f-c-ai-text-suggestions__suggestion-meta'

    const tone = suggestion.meta?.tone_label || suggestion.meta?.toneLabel
    if (tone) meta.appendChild(this.metaItem(tone))

    meta.appendChild(this.metaItem(`${suggestion.char_count || (suggestion.text || '').length} ${this.charsLabelValue}`))

    if (suggestion.meta?.over_limit && this.hasCharacterLimitValue) {
      meta.appendChild(this.metaItem(`> ${this.characterLimitValue}`))
    }

    return meta
  }

  metaItem (text) {
    const item = document.createElement('span')
    item.textContent = text
    return item
  }

  suggestionTextElement (text) {
    const span = document.createElement('span')
    span.className = 'f-c-ai-text-suggestions__suggestion-text'
    span.textContent = text
    return span
  }

  actionButton (action, label, text) {
    const button = document.createElement('button')
    button.type = 'button'
    button.className = `f-c-ai-text-suggestions__suggestion-${action}`
    button.textContent = action === 'copy' ? 'Copy' : 'OK'
    button.setAttribute('aria-label', label)
    button.setAttribute('title', label)
    button.setAttribute('data-action', `click->f-c-ai-text-suggestions#${action}`)
    button.setAttribute('data-f-c-ai-text-suggestions-text-param', text)
    return button
  }

  setLoading () {
    this.element.classList.add(this.loadingClass)
    this.hideStatus()
    this.suggestionsTarget.innerHTML = ''

    for (let i = 0; i < this.suggestionCountValue; i += 1) {
      const item = document.createElement('div')
      item.className = 'f-c-ai-text-suggestions__suggestion f-c-ai-text-suggestions__suggestion--loading'
      item.textContent = this.loadingTextValue
      this.suggestionsTarget.appendChild(item)
    }
  }

  showPanel () {
    this.panelTarget.hidden = false
    this.element.classList.add(this.openClass)
    this.buttonTarget.setAttribute('aria-expanded', 'true')
  }

  showError (message) {
    this.statusTarget.hidden = false
    this.statusTarget.textContent = message
  }

  hideStatus () {
    this.statusTarget.hidden = true
    this.statusTarget.textContent = ''
  }

  writeValue (input, value) {
    input.value = value
    input.dispatchEvent(new Event('input', { bubbles: true }))
    input.dispatchEvent(new Event('change', { bubbles: true }))
    input.dispatchEvent(new CustomEvent('folioConsoleCustomChange', { bubbles: true }))
  }

  markSelected (selectedElement) {
    this.clearSelection()
    selectedElement.classList.add('f-c-ai-text-suggestions__suggestion--selected')
  }

  clearSelection () {
    this.suggestionsTarget.querySelectorAll('.f-c-ai-text-suggestions__suggestion--selected').forEach((element) => {
      element.classList.remove('f-c-ai-text-suggestions__suggestion--selected')
    })
  }

  copyText (text) {
    if (navigator.clipboard?.writeText) {
      return navigator.clipboard.writeText(text)
    }

    const input = document.createElement('textarea')
    input.value = text
    input.setAttribute('readonly', 'readonly')
    input.style.position = 'absolute'
    input.style.left = '-9999px'
    document.body.appendChild(input)
    input.select()
    document.execCommand('copy')
    input.remove()

    return Promise.resolve()
  }

  nextRequestId () {
    this.requestSequence += 1
    return this.requestSequence
  }

  staleRequest (requestId) {
    return requestId !== this.requestSequence
  }

  abortRequest () {
    if (!this.abortController) return

    this.abortController.abort()
    this.abortController = null
  }

  trackingDetail () {
    return {
      integrationKey: this.integrationKeyValue,
      fieldKey: this.fieldKeyValue
    }
  }

  get targetInput () {
    return document.querySelector(this.targetSelectorValue)
  }

  get isOpen () {
    return !this.panelTarget.hidden
  }
})
