(() => {
  const registerTextSuggestionsGroupController = () => {
    window.Folio.Stimulus.register('f-ai-c-text-suggestions-group', class extends window.Stimulus.Controller {
      static targets = ['closeButton', 'instructions', 'panel', 'status', 'statusMessage']

      static values = {
        url: String,
        klass: String,
        recordId: String,
        key: String,
        componentId: String,
        suggestionCount: Number,
        fields: Array,
        open: { type: Boolean, default: false },
        status: { type: String, default: 'idle' }
      }

      connect () {
        this.request = window.Folio.Ai.asyncJobRequest({
          timeoutMs: () => 45000,
          onTimeout: () => this.handleTimeout()
        })
      }

      disconnect () {
        this.request.abort()
      }

      toggle (event) {
        this.stop(event)

        if (this.panelOpen) {
          this.close()
        } else {
          this.open()
        }
      }

      submit (event) {
        this.stop(event)
        this.load({ instructions: this.instructions })
      }

      onMessage (event) {
        this.request.receiveMessage(event?.detail?.message, (message) => this.applyMessageBusResult(message))
      }

      open () {
        this.panelTarget.hidden = false
        this.closeButtonTarget.hidden = false
        this.openValue = true
        if (!this.request.active) this.load()
      }

      close (event) {
        this.stop(event)
        const requestId = this.request.pendingRequestId
        this.request.abort()
        this.closeChildInputs(requestId)
        this.panelTarget.hidden = true
        this.closeButtonTarget.hidden = true
        this.openValue = false
        this.setStatus('idle')
      }

      load ({ instructions = null } = {}) {
        this.hideStatus()
        this.setStatus('loading')

        this.request.post({
          url: this.urlValue,
          body: this.requestPayload({ instructions }),
          onResponse: (response, request) => this.handleResponse(response, request),
          onError: (error) => {
            this.showStatus(window.Folio.Ai.errorMessage(error, this.genericErrorText))
            this.setStatus('idle')
          },
          onFinally: ({ pending }) => {
            if (!pending) this.setStatus('idle')
          }
        })
      }

      requestPayload ({ instructions }) {
        const payload = {
          klass: this.klassValue,
          id: this.recordIdValue,
          key: this.keyValue,
          grouped: true,
          component_id: this.componentIdValue,
          suggestion_count: this.suggestionCountValue,
          fields: this.fieldsValue,
          message_bus_client_id: this.messageBusClientId,
          current_form_snapshot_json: JSON.stringify(window.Folio.Ai.formSnapshot(this.form))
        }

        if (instructions !== null) payload.instructions = instructions

        return payload
      }

      handleResponse (response, { pending, applyBufferedMessage }) {
        this.dispatchFragments('loading', response.meta?.fragments || {}, response.meta?.request_id)

        if (applyBufferedMessage((message) => this.applyMessageBusResult(message))) return

        if (pending) this.setStatus('waiting')
      }

      applyMessageBusResult (message) {
        this.dispatchFragments('result', message.data?.fragments || {}, message.data?.request_id)
        this.request.finish()
        this.setStatus('idle')
      }

      dispatchFragments (eventName, fragments, requestId) {
        this.fieldsValue.forEach((field) => {
          const input = this.inputForField(field)
          if (!input) return

          this.dispatch(eventName, {
            target: input,
            bubbles: true,
            detail: {
              html: fragments[field.component_id],
              requestId
            }
          })
        })
      }

      closeChildInputs (requestId) {
        this.fieldsValue.forEach((field) => {
          const input = this.inputForField(field)
          if (!input) return

          input.dispatchEvent(new CustomEvent('f-ai-input/close', {
            bubbles: true,
            detail: { requestId }
          }))
        })
      }

      inputForField (field) {
        const componentId = window.Folio.Ai.cssEscape(field.component_id)
        return this.element.querySelector(`.f-ai-input[data-f-ai-input-component-id-value="${componentId}"]`)
      }

      handleTimeout () {
        this.dispatchFragments('result', {}, this.request.pendingRequestId)
        this.showStatus(window.Folio.i18n(window.Folio.Ai.i18n, 'requestTimeout'))
        this.request.finish()
        this.setStatus('idle')
      }

      showStatus (message) {
        if (!message) return

        this.statusMessageTarget.textContent = message
        this.statusTarget.hidden = false
      }

      hideStatus () {
        this.statusTarget.hidden = true
      }

      setStatus (status) {
        this.statusValue = status
      }

      stop (event) {
        if (!event) return

        event.preventDefault()
        event.currentTarget.blur()
      }

      get panelOpen () {
        return !this.panelTarget.hidden
      }

      get instructions () {
        return this.hasInstructionsTarget ? this.instructionsTarget.value : ''
      }

      get form () {
        return this.element.closest('form')
      }

      get messageBusClientId () {
        return window.MessageBus?.clientId || null
      }

      get genericErrorText () {
        return window.Folio.i18n(window.Folio.Ai.i18n, 'genericError')
      }
    })
  }

  if (window.Folio?.Stimulus?.register && window.Stimulus?.Controller) {
    registerTextSuggestionsGroupController()
  } else {
    document.addEventListener('folio:stimulus-ready', registerTextSuggestionsGroupController, { once: true })
  }

  if (window.Folio?.MessageBus?.callbacks) {
    window.Folio.MessageBus.callbacks['f-ai-c-text-suggestions-group'] = (message) => {
      if (!message) return
      if (message.type !== 'Folio::Ai::TextSuggestionsJob') return
      if (!message.data?.grouped) return

      const componentId = window.Folio.Ai.cssEscape(message.data.component_id)
      const selector = `.f-ai-c-text-suggestions-group[data-f-ai-c-text-suggestions-group-component-id-value="${componentId}"]`

      document.querySelectorAll(selector).forEach((element) => {
        element.dispatchEvent(new CustomEvent('f-ai-c-text-suggestions-group/message', { detail: { message } }))
      })
    }
  }
})()
