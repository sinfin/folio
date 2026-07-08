(() => {
  const CONTROLLER_NAME = 'f-ai-input'
  const INPUT_CLASS_NAME = 'f-ai-input'
  const INPUT_OPEN_CLASS = `${INPUT_CLASS_NAME}--open`
  const PANEL_CLASS_NAME = 'f-ai-c-text-suggestions'
  const TEXT_SUGGESTIONS_JOB_TYPE = 'Folio::Ai::TextSuggestionsJob'
  const STATUS_IDLE = 'idle'
  const STATUS_INITIAL_LOADING = 'initial-loading'
  const STATUS_WAITING_FOR_SUGGESTIONS = 'waiting-for-suggestions'
  const STATUS_SUBMITTING_INSTRUCTIONS = 'submitting-instructions'
  const CLIENT_ERROR_STATUSES = [STATUS_WAITING_FOR_SUGGESTIONS, STATUS_SUBMITTING_INSTRUCTIONS]
  const REQUEST_TIMEOUT_MS = 45000

  let openController = null

  const messageComponentIds = (message) => {
    return [...new Set([
      message.data.component_id,
      ...Object.keys(message.data.fragments || {})
    ].filter(Boolean))]
  }

  const dispatchMessageToInput = (input, message) => {
    input.dispatchEvent(new CustomEvent(`${CONTROLLER_NAME}/message`, { detail: { message } }))
  }

  const registerAiInputController = () => {
    window.Folio.Stimulus.register(CONTROLLER_NAME, class extends window.Stimulus.Controller {
      static targets = ['input']

      static values = {
        url: String,
        klass: String,
        recordId: String,
        key: String,
        group: Boolean,
        suggestionCount: { type: Number, default: 3 },
        componentId: String,
        status: { type: String, default: STATUS_IDLE }
      }

      connect () {
        this.request = window.Folio.Ai.asyncJobRequest({
          timeoutMs: () => REQUEST_TIMEOUT_MS,
          onTimeout: () => this.handleTimeout()
        })
        this.setStatus(STATUS_IDLE)
        this.syncControls()
      }

      statusValueChanged () {
        this.syncControls()
      }

      disconnect () {
        this.abortRequest()

        if (openController === this) openController = null
      }

      toggle (event) {
        this.stopEvent(event)

        if (this.isOpen) {
          this.close()
        } else {
          this.open()
        }
      }

      open () {
        if (!this.input || !this.customHtmlElement) return

        if (openController && openController !== this) openController.close()
        openController = this

        this.startSession()
        this.loadHtml()
      }

      close (event) {
        this.stopEvent(event)
        this.abortRequest()
        if (this.customHtmlElement) this.customHtmlElement.innerHTML = ''
        this.element.classList.remove(INPUT_OPEN_CLASS)
        this.setStatus(STATUS_IDLE)
        this.clearSession()

        if (openController === this) openController = null

        this.syncControls()
      }

      regenerate (event) {
        this.stopEvent(event)
        this.loadHtml({ instructions: event?.detail?.instructions || '' })
      }

      acceptSuggestion (event) {
        const text = event?.detail && typeof event.detail.text !== 'undefined' ? event.detail.text : ''
        if (!this.input) return

        this.writeInputValue(text, { folioAutosave: false })
        this.element.dataset.fAiInputSelectedText = text
        this.element.dataset.fAiInputUndoVisible = 'true'
        if (this.undoElement) this.undoElement.hidden = false
      }

      undoSuggestion (event) {
        this.stopEvent(event)

        const snapshot = this.sessionSnapshot
        if (snapshot === null || !this.input) return

        this.writeInputValue(snapshot, { folioAutosave: false })
        delete this.element.dataset.fAiInputSelectedText
        this.element.dataset.fAiInputUndoVisible = 'false'
        this.hideUndoButton()
        this.dispatchSuggestionStale()

        this.dispatch('undo', { bubbles: true, detail: this.trackingDetail() })
      }

      onInput () {
        if (!this.input) return

        const selected = this.element.dataset.fAiInputSelectedText
        if (!selected || this.input.value === selected) return

        delete this.element.dataset.fAiInputSelectedText
        this.dispatchSuggestionStale()
      }

      onMessage (event) {
        this.request.receiveMessage(event?.detail?.message, (message) => this.applyMessageBusResult(message))
      }

      loadHtml ({ instructions = null } = {}) {
        this.setLoadingStatus(instructions === null ? STATUS_INITIAL_LOADING : STATUS_SUBMITTING_INSTRUCTIONS)

        this.request.post({
          url: this.urlValue,
          body: this.requestPayload({ instructions }),
          onResponse: (response, request) => this.handleResponse(response, request),
          onError: (error) => {
            this.handleError(error)
            this.finishLoading()
          },
          onFinally: ({ pending }) => {
            if (!pending) this.finishLoading()
          }
        })
      }

      requestPayload ({ instructions }) {
        const payload = {
          klass: this.klassValue,
          id: this.recordIdValue,
          key: this.keyValue,
          group: this.groupValue,
          component_id: this.componentIdValue,
          suggestion_count: this.suggestionCountValue,
          message_bus_client_id: this.messageBusClientId,
          current_form_snapshot_json: JSON.stringify(window.Folio.Ai.formSnapshot(this.input?.form))
        }

        if (instructions !== null) payload.instructions = instructions

        return payload
      }

      handleResponse (response, { pending, applyBufferedMessage }) {
        this.handleHtml(response.data)

        if (applyBufferedMessage((message) => this.applyMessageBusResult(message))) return

        if (pending) this.setStatus(STATUS_WAITING_FOR_SUGGESTIONS)
      }

      handleHtml (html) {
        if (!this.customHtmlElement) return

        const instructionsState = window.Folio.Ai.textInputState(this.instructionsElement)

        this.customHtmlElement.innerHTML = html || ''
        window.Folio.Ai.restoreTextInputState(this.instructionsElement, instructionsState)
        this.element.classList.add(INPUT_OPEN_CLASS)
        this.syncControls()
      }

      handleError (error) {
        this.showClientError(window.Folio.Ai.errorMessage(error, this.genericErrorText))
      }

      handleTimeout () {
        this.showClientError(window.Folio.i18n(window.Folio.Ai.i18n, 'requestTimeout'))
        this.finishLoading()
      }

      showClientError (message) {
        const errorMessage = message || this.genericErrorText
        const textSuggestions = this.textSuggestionsElement

        if (!this.shouldDispatchClientError || !textSuggestions) {
          this.alertInitialClientError(errorMessage)
          return
        }

        this.dispatch('clientError', {
          target: textSuggestions,
          bubbles: true,
          detail: { message: errorMessage }
        })
      }

      alertInitialClientError (message) {
        if (this.statusValue !== STATUS_INITIAL_LOADING) return

        window.alert(message)
      }

      applyMessageBusResult (message) {
        const html = message.data.fragments?.[this.componentIdValue] || message.data.html

        if (html) {
          this.handleHtml(html)
        } else {
          this.handleError(new Error(this.genericErrorText))
        }

        this.finishLoading()
      }

      abortRequest ({ resetStatus = true } = {}) {
        this.request.abort()
        if (resetStatus) this.setStatus(STATUS_IDLE)
      }

      finishLoading () {
        this.request.finish()
        this.setStatus(STATUS_IDLE)
        if (!this.isOpen) this.element.classList.remove(INPUT_OPEN_CLASS)
        this.syncControls()
      }

      setLoadingStatus (status) {
        this.setStatus(status)
        this.element.classList.add(INPUT_OPEN_CLASS)
        this.syncControls()
      }

      setStatus (status) {
        this.statusValue = status
      }

      startSession () {
        this.element.dataset.fAiInputSnapshot = this.input.value || ''
        this.element.dataset.fAiInputUndoVisible = 'false'
        delete this.element.dataset.fAiInputSelectedText
        this.hideUndoButton()
      }

      clearSession () {
        delete this.element.dataset.fAiInputSnapshot
        delete this.element.dataset.fAiInputUndoVisible
        delete this.element.dataset.fAiInputSelectedText
        this.hideUndoButton()
      }

      hideUndoButton () {
        if (this.undoElement) this.undoElement.hidden = true
      }

      writeInputValue (value, { folioAutosave = true } = {}) {
        if (!this.input) return

        window.Folio.Ai.writeInputValue(this.input, value, { folioAutosave })
      }

      dispatchSuggestionStale () {
        const panel = this.textSuggestionsElement
        if (!panel) return

        this.dispatch('suggestionStale', { target: panel, bubbles: true })
      }

      trackingDetail () {
        return { key: this.keyValue }
      }

      stopEvent (event) {
        if (!event) return

        event.preventDefault()
        event.target?.blur()
      }

      syncControls () {
        if (this.buttonElement) {
          this.buttonElement.setAttribute('aria-expanded', this.isOpen ? 'true' : 'false')
        }
      }

      get input () {
        return this.hasInputTarget ? this.inputTarget : null
      }

      get buttonElement () {
        return this.element.querySelector('.f-ai-input__button')
      }

      get undoElement () {
        return this.element.querySelector('.f-ai-input__undo')
      }

      get customHtmlElement () {
        return this.element.querySelector('.f-ai-input__custom-html')
      }

      get isOpen () {
        return !!this.customHtmlElement && this.customHtmlElement.childElementCount > 0
      }

      get shouldDispatchClientError () {
        return CLIENT_ERROR_STATUSES.includes(this.statusValue)
      }

      get textSuggestionsElement () {
        return this.customHtmlElement?.querySelector(`.${PANEL_CLASS_NAME}`)
      }

      get instructionsElement () {
        return this.textSuggestionsElement?.querySelector('.f-ai-c-text-suggestions__instructions-input')
      }

      get messageBusClientId () {
        return window.MessageBus?.clientId || null
      }

      get genericErrorText () {
        return window.Folio.i18n(window.Folio.Ai.i18n, 'genericError')
      }

      get sessionSnapshot () {
        return Object.prototype.hasOwnProperty.call(this.element.dataset, 'fAiInputSnapshot')
          ? this.element.dataset.fAiInputSnapshot
          : null
      }
    })
  }

  if (window.Folio?.Stimulus?.register && window.Stimulus?.Controller) {
    registerAiInputController()
  } else {
    document.addEventListener('folio:stimulus-ready', registerAiInputController, { once: true })
  }

  if (window.Folio?.MessageBus?.callbacks) {
    window.Folio.MessageBus.callbacks[CONTROLLER_NAME] = (message) => {
      if (!message) return
      if (message.type !== TEXT_SUGGESTIONS_JOB_TYPE) return

      for (const componentId of messageComponentIds(message)) {
        const selector = `.${INPUT_CLASS_NAME}[data-f-ai-input-component-id-value="${window.Folio.Ai.cssEscape(componentId)}"]`
        const inputs = document.querySelectorAll(selector)

        for (const input of inputs) dispatchMessageToInput(input, message)
      }
    }
  }
})()
