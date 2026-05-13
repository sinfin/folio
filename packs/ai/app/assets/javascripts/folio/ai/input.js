(() => {
  const CONTROLLER_NAME = 'f-ai-input'
  const INPUT_CLASS_NAME = 'f-ai-input'
  const INPUT_OPEN_CLASS = `${INPUT_CLASS_NAME}--open`
  const CONTROLS_OPEN_CLASS = `${INPUT_CLASS_NAME}__controls--open`
  const PANEL_CLASS_NAME = 'f-ai-c-text-suggestions'
  const TEXT_SUGGESTIONS_JOB_TYPE = 'Folio::Ai::TextSuggestionsJob'
  const STATUS_IDLE = 'idle'
  const STATUS_INITIAL_LOADING = 'initial-loading'
  const STATUS_WAITING_FOR_SUGGESTIONS = 'waiting-for-suggestions'
  const STATUS_SUBMITTING_INSTRUCTIONS = 'submitting-instructions'
  const CLIENT_ERROR_STATUSES = [STATUS_WAITING_FOR_SUGGESTIONS, STATUS_SUBMITTING_INSTRUCTIONS]
  let openController = null

  const cssEscape = (value) => {
    value = value.toString()

    if (window.CSS?.escape) return window.CSS.escape(value)

    return value.replace(/["\\]/g, '\\$&')
  }

  const registerAiInputController = () => {
    window.Folio.Stimulus.register(CONTROLLER_NAME, class extends window.Stimulus.Controller {
      static targets = ['input', 'button', 'customHtml', 'undo']

      static values = {
        url: String,
        instructionsUrl: String,
        klass: String,
        recordId: String,
        integrationKey: String,
        fieldKey: String,
        suggestionCount: { type: Number, default: 3 },
        componentId: String,
        currentStatePolicy: { type: String, default: 'persisted_record' },
        showMeta: { type: Boolean, default: false },
        requestTimeoutMs: { type: Number, default: 45000 },
        loadingText: String,
        genericErrorText: String,
        requestTimeoutText: String,
        status: { type: String, default: STATUS_IDLE }
      }

      connect () {
        this.requestSequence = 0
        this.requestTimeoutId = null
        this.requestTimedOut = false
        this.pendingTextSuggestionsRequestId = null
        this.cancelledTextSuggestionsRequestIds = new Set()
        this.textSuggestionsMessages = {}
        this.abortController = null
        this.awaitingTextSuggestionsResult = false
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
        this.stopActionEvent(event)

        if (this.isOpen) {
          this.close()
        } else {
          this.open()
        }
      }

      open () {
        if (!this.input || !this.hasCustomHtmlTarget) return

        if (openController && openController !== this) openController.close()
        openController = this

        this.startSession()
        this.loadHtml({ url: this.urlValue })
      }

      close (event) {
        this.stopActionEvent(event)
        this.abortRequest()
        this.customHtmlTarget.innerHTML = ''
        this.element.classList.remove(INPUT_OPEN_CLASS)
        this.setStatus(STATUS_IDLE)
        this.clearSession()

        if (openController === this) openController = null

        this.syncControls()
      }

      regenerate (event) {
        this.stopActionEvent(event)
        this.loadHtml({
          url: this.instructionsUrlValue,
          instructions: event?.detail?.instructions || ''
        })
      }

      acceptSuggestion (event) {
        const text = event.detail && typeof event.detail.text !== 'undefined' ? event.detail.text : ''
        if (!this.input) return

        this.writeInputValue(text)
        this.element.dataset.fAiInputSelectedText = text
        this.element.dataset.fAiInputUndoVisible = 'true'
        if (this.hasUndoTarget) this.undoTarget.hidden = false
      }

      undoSuggestion (event) {
        this.stopActionEvent(event)

        const snapshot = this.sessionSnapshot
        if (snapshot === null) return
        if (!this.input) return

        this.writeInputValue(snapshot)
        delete this.element.dataset.fAiInputSelectedText
        this.element.dataset.fAiInputUndoVisible = 'false'
        this.hideUndoButton()
        this.dispatchSuggestionStale()

        this.dispatch('undo', { bubbles: true, detail: this.trackingDetail() })
      }

      onInputSyncAiSuggestion () {
        if (!this.input) return

        const selected = this.element.dataset.fAiInputSelectedText
        if (!selected) return
        if (this.input.value === selected) return

        delete this.element.dataset.fAiInputSelectedText
        this.dispatchSuggestionStale()
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

      onMessage (event) {
        const message = event?.detail?.message
        if (!message || !message.data || !message.data.request_id) return
        if (this.cancelledTextSuggestionsRequestIds.delete(message.data.request_id)) return
        if (!this.awaitingTextSuggestionsResult) return
        if (!this.pendingTextSuggestionsRequestId) {
          this.textSuggestionsMessages[message.data.request_id] = message
          return
        }
        if (message.data.request_id !== this.pendingTextSuggestionsRequestId) return

        this.applyMessageBusResult(message)
      }

      loadHtml ({ url, instructions = null }) {
        const requestId = this.nextRequestId()
        const body = this.requestPayload({ instructions })
        this.abortRequest()
        this.abortController = new AbortController()
        this.requestTimedOut = false
        this.awaitingTextSuggestionsResult = true
        this.setRequestTimeout(requestId)
        this.setLoadingStatus(instructions === null ? STATUS_INITIAL_LOADING : STATUS_SUBMITTING_INSTRUCTIONS)

        const request = window.Folio.Api.apiPost(url, body, this.abortController.signal)

        request
          .then((response) => {
            if (this.staleRequest(requestId)) return

            this.handleHtml(response.data)
            this.pendingTextSuggestionsRequestId = response.meta?.request_id || null
            const receivedBufferedResult = this.applyBufferedMessageBusMessage()
            if (receivedBufferedResult) return

            if (this.pendingTextSuggestionsRequestId) {
              this.setStatus(STATUS_WAITING_FOR_SUGGESTIONS)
              return
            }

            this.handleError(new Error(this.genericErrorTextValue))
            this.finishLoading()
          })
          .catch((error) => {
            if (this.staleRequest(requestId)) return

            if (error.name === 'AbortError') {
              if (this.requestTimedOut) this.handleTimeout()
              return
            }

            this.handleError(error)
            this.finishLoading()
          })
          .finally(() => {
            if (this.staleRequest(requestId)) return

            this.abortController = null

            if (!this.pendingTextSuggestionsRequestId) {
              this.finishLoading()
            }
          })
      }

      requestPayload ({ instructions }) {
        const payload = {
          klass: this.klassValue,
          id: this.recordIdValue,
          integration_key: this.integrationKeyValue,
          field_key: this.fieldKeyValue,
          component_id: this.componentIdValue,
          show_meta: this.showMetaValue,
          suggestion_count: this.suggestionCountValue,
          message_bus_client_id: this.messageBusClientId
        }

        if (instructions !== null) {
          payload.instructions = instructions
        }

        if (this.usesCurrentFormSnapshot) {
          payload.current_form_snapshot_json = JSON.stringify(this.currentFormSnapshot())
        }

        return payload
      }

      handleHtml (html) {
        this.customHtmlTarget.innerHTML = html
        this.element.classList.add(INPUT_OPEN_CLASS)
        this.syncControls()
      }

      handleError (error) {
        this.showClientError(this.errorMessage(error))
      }

      handleTimeout () {
        this.showClientError(this.timeoutErrorText())
      }

      errorMessage (error) {
        const responseData = error.responseData || {}
        const detail = responseData.message || this.errorDetail(responseData)

        return detail || error.message || this.genericErrorTextValue
      }

      errorDetail (responseData) {
        if (!responseData.errors || responseData.errors.length === 0) return null

        return responseData.errors[0].detail || responseData.errors[0].title
      }

      setLoadingStatus (status) {
        this.setStatus(status)
        this.element.classList.add(INPUT_OPEN_CLASS)
        this.syncControls()
      }

      setStatus (status) {
        this.statusValue = status
      }

      showClientError (message) {
        const textSuggestions = this.textSuggestionsElement
        if (!this.shouldDispatchClientError || !textSuggestions) return

        this.dispatch('clientError', {
          target: textSuggestions,
          bubbles: true,
          detail: { message }
        })
      }

      applyBufferedMessageBusMessage () {
        const message = this.textSuggestionsMessages[this.pendingTextSuggestionsRequestId]
        if (!message) return false

        this.applyMessageBusResult(message)
        return true
      }

      applyMessageBusResult (message) {
        delete this.textSuggestionsMessages[message.data.request_id]

        if (message.data.html) {
          this.handleHtml(message.data.html)
        } else {
          this.handleError(new Error(this.genericErrorTextValue))
        }

        this.finishLoading()
      }

      nextRequestId () {
        this.requestSequence += 1
        return this.requestSequence
      }

      staleRequest (requestId) {
        return requestId !== this.requestSequence
      }

      abortRequest ({ resetStatus = true } = {}) {
        this.cancelPendingTextSuggestionsRequest()
        this.clearRequestTimeout()
        this.requestTimedOut = false
        this.pendingTextSuggestionsRequestId = null
        this.textSuggestionsMessages = {}
        this.awaitingTextSuggestionsResult = false
        if (resetStatus) this.setStatus(STATUS_IDLE)

        if (!this.abortController) return

        this.abortController.abort()
        this.abortController = null
      }

      cancelPendingTextSuggestionsRequest () {
        if (!this.pendingTextSuggestionsRequestId) return

        this.cancelledTextSuggestionsRequestIds.add(this.pendingTextSuggestionsRequestId)
      }

      setRequestTimeout (requestId) {
        if (this.requestTimeoutMsValue <= 0) return

        this.requestTimeoutId = window.setTimeout(() => {
          if (this.staleRequest(requestId)) return

          this.requestTimedOut = true

          if (this.abortController) {
            this.abortController.abort()
            return
          }

          this.pendingTextSuggestionsRequestId = null
          this.handleTimeout()
          this.finishLoading()
        }, this.requestTimeoutMsValue)
      }

      clearRequestTimeout () {
        if (!this.requestTimeoutId) return

        window.clearTimeout(this.requestTimeoutId)
        this.requestTimeoutId = null
      }

      timeoutErrorText () {
        if (this.hasRequestTimeoutTextValue && this.requestTimeoutTextValue) {
          return this.requestTimeoutTextValue
        }

        return this.genericErrorTextValue
      }

      finishLoading () {
        this.clearRequestTimeout()
        this.requestTimedOut = false
        this.pendingTextSuggestionsRequestId = null
        this.awaitingTextSuggestionsResult = false
        this.setStatus(STATUS_IDLE)
        this.syncControls()
      }

      currentFormSnapshot () {
        const form = this.input?.form
        if (!form) return {}

        const snapshot = {}
        const formData = new FormData(form)

        formData.forEach((value, key) => {
          if (value instanceof File) return

          this.addSnapshotValue(snapshot, key, value.toString())
        })

        return snapshot
      }

      addSnapshotValue (snapshot, key, value) {
        if (Object.prototype.hasOwnProperty.call(snapshot, key)) {
          snapshot[key] = Array.isArray(snapshot[key])
            ? [...snapshot[key], value]
            : [snapshot[key], value]
        } else {
          snapshot[key] = value
        }
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
        if (this.hasUndoTarget) {
          this.undoTarget.hidden = true
        }
      }

      writeInputValue (value) {
        if (!this.input) return

        this.input.value = value
        this.input.dispatchEvent(new Event('input', { bubbles: true }))
        this.input.dispatchEvent(new Event('change', { bubbles: true }))
        this.input.dispatchEvent(new CustomEvent('folioConsoleCustomChange', { bubbles: true }))
      }

      dispatchSuggestionStale () {
        if (!this.hasCustomHtmlTarget) return

        const panel = this.customHtmlTarget.querySelector(`.${PANEL_CLASS_NAME}`)
        if (!panel) return

        this.dispatch('suggestionStale', { target: panel, bubbles: true })
      }

      trackingDetail () {
        return {
          integrationKey: this.integrationKeyValue,
          fieldKey: this.fieldKeyValue
        }
      }

      stopActionEvent (event) {
        if (!event) return

        event.preventDefault()
        event.stopPropagation()
        event.target.blur()
      }

      syncControls () {
        if (this.hasButtonTarget) {
          this.buttonTarget.setAttribute('aria-expanded', this.isOpen ? 'true' : 'false')
        }

        this.controlsElement?.classList.toggle(CONTROLS_OPEN_CLASS, this.isOpen)
      }

      get input () {
        return this.hasInputTarget ? this.inputTarget : null
      }

      get controlsElement () {
        return this.hasButtonTarget ? this.buttonTarget.closest('.f-ai-input__controls') : null
      }

      get isOpen () {
        return this.hasCustomHtmlTarget && this.customHtmlTarget.childElementCount > 0
      }

      get shouldDispatchClientError () {
        return CLIENT_ERROR_STATUSES.includes(this.statusValue)
      }

      get textSuggestionsElement () {
        if (!this.hasCustomHtmlTarget) return null

        return this.customHtmlTarget.querySelector(`.${PANEL_CLASS_NAME}`)
      }

      get usesCurrentFormSnapshot () {
        return this.currentStatePolicyValue === 'current_form_snapshot'
      }

      get messageBusClientId () {
        return window.MessageBus?.clientId || null
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
      if (!message.data || !message.data.component_id) return

      const selector = `.${INPUT_CLASS_NAME}[data-f-ai-input-component-id-value="${cssEscape(message.data.component_id)}"]`
      const inputs = document.querySelectorAll(selector)

      for (const input of inputs) {
        input.dispatchEvent(new CustomEvent(`${CONTROLLER_NAME}/message`, { detail: { message } }))
      }
    }
  }
})()
