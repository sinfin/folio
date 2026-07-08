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

  const registerAiInputController = () => {
    window.Folio.Stimulus.register(CONTROLLER_NAME, class extends window.Stimulus.Controller {
      static targets = ['input', 'button', 'customHtml', 'undo', 'instructions']

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
        this.request = new window.Folio.Ai.AsyncJobRequest({
          timeoutMs: () => this.requestTimeoutMsValue,
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
        this.handleActionEvent(event)

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
        this.handleActionEvent(event)
        this.abortRequest()
        this.customHtmlTarget.innerHTML = ''
        this.element.classList.remove(INPUT_OPEN_CLASS)
        this.setStatus(STATUS_IDLE)
        this.clearSession()

        if (openController === this) openController = null

        this.syncControls()
      }

      openFromBatch (event) {
        if (!this.input || !this.hasCustomHtmlTarget) return

        this.abortRequest({ resetStatus: false })
        if (openController === this) openController = null

        this.startSession()
        this.handleHtml(event?.detail?.html || '')

        if (event?.detail?.pending) {
          this.setStatus(STATUS_WAITING_FOR_SUGGESTIONS)
        } else {
          this.finishLoading()
        }
      }

      handleBatchHtml (event) {
        if (!this.input || !this.hasCustomHtmlTarget) return

        this.abortRequest({ resetStatus: false })
        this.handleHtml(event?.detail?.html || '')
        this.finishLoading()
      }

      handleBatchClientError (event) {
        const html = event?.detail?.html

        if (html && this.hasCustomHtmlTarget) {
          this.handleHtml(html)
        }

        this.showClientError(event?.detail?.message || this.genericErrorTextValue)
        this.finishLoading()
      }

      closeFromBatch (event) {
        this.close(event)
      }

      regenerate (event) {
        this.handleActionEvent(event)
        this.loadHtml({
          url: this.instructionsUrlValue,
          instructions: event?.detail?.instructions || ''
        })
      }

      acceptSuggestion (event) {
        const text = event.detail && typeof event.detail.text !== 'undefined' ? event.detail.text : ''
        if (!this.input) return

        this.writeInputValue(text, { folioAutosave: false })
        this.element.dataset.fAiInputSelectedText = text
        this.element.dataset.fAiInputUndoVisible = 'true'
        if (this.hasUndoTarget) this.undoTarget.hidden = false
      }

      undoSuggestion (event) {
        this.handleActionEvent(event)

        const snapshot = this.sessionSnapshot
        if (snapshot === null) return
        if (!this.input) return

        this.writeInputValue(snapshot, { folioAutosave: false })
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

        this.request.receiveMessage(message, (message) => this.applyMessageBusResult(message))
      }

      loadHtml ({ url, instructions = null }) {
        const body = this.requestPayload({ instructions })
        this.setLoadingStatus(instructions === null ? STATUS_INITIAL_LOADING : STATUS_SUBMITTING_INSTRUCTIONS)

        this.request.post({
          url,
          body,
          onResponse: (response, { pending, applyBufferedMessage }) => {
            this.handleHtml(response.data)
            const receivedBufferedResult = applyBufferedMessage((message) => this.applyMessageBusResult(message))
            if (receivedBufferedResult) return

            if (pending) this.setStatus(STATUS_WAITING_FOR_SUGGESTIONS)
          },
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
          payload.current_form_snapshot_json = JSON.stringify(window.Folio.Ai.formSnapshot(this.input?.form))
        }

        return payload
      }

      handleHtml (html) {
        const instructionsState = this.currentInstructionsState()

        this.customHtmlTarget.innerHTML = html
        this.restoreInstructionsState(instructionsState)
        this.element.classList.add(INPUT_OPEN_CLASS)
        this.syncControls()
      }

      currentInstructionsState () {
        const instructions = this.instructionsElement
        if (!instructions) return null

        return {
          value: instructions.value,
          focused: document.activeElement === instructions,
          selectionStart: instructions.selectionStart,
          selectionEnd: instructions.selectionEnd,
          selectionDirection: instructions.selectionDirection
        }
      }

      restoreInstructionsState (state) {
        if (!state) return

        const instructions = this.instructionsElement
        if (!instructions) return

        instructions.value = state.value

        if (state.focused) {
          instructions.focus()
          instructions.setSelectionRange(state.selectionStart, state.selectionEnd, state.selectionDirection)
        }
      }

      handleError (error) {
        this.showClientError(window.Folio.Ai.errorMessage(error, this.genericErrorTextValue))
      }

      handleTimeout () {
        this.showClientError(window.Folio.Ai.timeoutErrorText(this, this.genericErrorTextValue))
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
        const errorMessage = message || this.genericErrorTextValue
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
        if (message.data.html) {
          this.handleHtml(message.data.html)
        } else {
          this.handleError(new Error(this.genericErrorTextValue))
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

      writeInputValue (value, { folioAutosave = true } = {}) {
        if (!this.input) return

        this.input.value = value
        this.dispatchInputEvent('input', { folioAutosave })
        this.dispatchInputEvent('change', { folioAutosave })
        this.dispatchInputEvent('folioConsoleCustomChange', { folioAutosave })
      }

      dispatchInputEvent (type, { folioAutosave }) {
        this.input.dispatchEvent(new CustomEvent(type, {
          bubbles: true,
          detail: { folioAutosave }
        }))
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

      handleActionEvent (event) {
        if (!event) return

        event.preventDefault()
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

      get instructionsElement () {
        return this.hasInstructionsTarget ? this.instructionsTarget : null
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

      const selector = `.${INPUT_CLASS_NAME}[data-f-ai-input-component-id-value="${window.Folio.Ai.cssEscape(message.data.component_id)}"]`
      const inputs = document.querySelectorAll(selector)

      for (const input of inputs) {
        input.dispatchEvent(new CustomEvent(`${CONTROLLER_NAME}/message`, { detail: { message } }))
      }
    }
  }
})()
