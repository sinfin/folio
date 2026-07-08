(() => {
  const INPUT_CLASS_NAME = 'f-ai-input'
  const STATE_IDLE = 'idle'
  const STATE_ACTIVE = 'active'
  const STATE_LOADING = 'loading'

  const registerTextSuggestionsGroupController = () => {
    window.Folio.Stimulus.register('f-ai-c-text-suggestions-group', class extends window.Stimulus.Controller {
      static values = {
        url: String,
        instructionsUrl: String,
        integrationKey: String,
        fieldKey: String,
        requestTimeoutMs: { type: Number, default: 45000 },
        genericErrorText: String,
        requestTimeoutText: String,
        state: { type: String, default: STATE_IDLE }
      }

      connect () {
        this.request = new window.Folio.Ai.AsyncJobRequest({
          timeoutMs: () => this.requestTimeoutMsValue,
          onTimeout: () => this.handleTimeout()
        })
        this.openedPanels = false
      }

      stateValueChanged () {
        this.dispatchStateToChildren()
      }

      disconnect () {
        this.abortRequest({ resetUi: false })
      }

      generate (event) {
        this.handleActionEvent(event)
        this.loadHtml({
          url: this.urlValue,
          instructions: null
        })
      }

      regenerate (event) {
        this.handleActionEvent(event)
        this.loadHtml({
          url: this.instructionsUrlValue,
          instructions: event?.detail?.instructions || ''
        })
      }

      close (event) {
        this.handleActionEvent(event)
        this.abortRequest()
        this.fieldElements.forEach((field) => this.dispatchToField(field, 'close'))
      }

      onWindowKeydown (event) {
        if (!this.isActive) return
        if (event.key !== 'Escape') return

        this.close(event)
      }

      onMessage (event) {
        const message = event?.detail?.message
        if (!message || !message.data || !message.data.request_id) return
        if (message.data.integration_key !== this.integrationKeyValue) return
        if (message.data.field_key !== this.fieldKeyValue) return

        this.request.receiveMessage(message, (message) => this.applyMessageBusResult(message))
      }

      loadHtml ({ url, instructions = null }) {
        const fieldElements = this.fieldElements
        const form = this.sharedForm(fieldElements)
        if (!form) return

        const body = this.requestPayload({ fieldElements, form, instructions })

        this.openedPanels = false
        this.startUi()

        this.request.post({
          url,
          body,
          onResponse: (response, { pending, applyBufferedMessage }) => {
            this.distributePanels(response.data?.panels, {
              eventName: 'open',
              pending
            })

            const receivedBufferedResult = applyBufferedMessage((message) => this.applyMessageBusResult(message))
            if (receivedBufferedResult) return

            if (!pending) this.finishLoading()
          },
          onError: (error) => {
            this.showClientError(window.Folio.Ai.errorMessage(error, this.genericErrorTextValue))
            this.finishLoading()
          },
          onFinally: ({ pending }) => {
            if (!pending) this.finishLoading()
          }
        })
      }

      requestPayload ({ fieldElements, form, instructions }) {
        const anchorField = fieldElements[0]
        const payload = {
          klass: anchorField?.dataset.fAiInputKlassValue,
          id: anchorField?.dataset.fAiInputRecordIdValue,
          integration_key: this.integrationKeyValue,
          field_key: this.fieldKeyValue,
          message_bus_client_id: this.messageBusClientId,
          fields: fieldElements.map((field) => this.fieldPayload(field))
        }

        if (instructions !== null) {
          payload.instructions = instructions
        }

        if (this.usesCurrentFormSnapshot(fieldElements)) {
          payload.current_form_snapshot_json = JSON.stringify(window.Folio.Ai.formSnapshot(form))
        }

        return payload
      }

      fieldPayload (field) {
        const dataset = field.dataset

        return {
          integration_key: dataset.fAiInputIntegrationKeyValue,
          field_key: dataset.fAiInputFieldKeyValue,
          component_id: dataset.fAiInputComponentIdValue,
          show_meta: dataset.fAiInputShowMetaValue
        }
      }

      distributePanels (panels, { eventName, pending }) {
        let openedPanelCount = 0

        Object.entries(panels || {}).forEach(([componentId, html]) => {
          const field = this.fieldForComponentId(componentId)
          if (!field) return

          if (eventName === 'open') openedPanelCount += 1

          this.dispatchToField(field, eventName, {
            html,
            pending
          })
        })

        if (openedPanelCount > 0) this.openedPanels = true
      }

      applyMessageBusResult (message) {
        if (message.data.panels) {
          this.distributePanels(message.data.panels, {
            eventName: 'html',
            pending: false
          })
        } else {
          this.showClientError(this.genericErrorTextValue)
        }

        this.finishLoading()
      }

      sharedForm (fieldElements) {
        if (fieldElements.length === 0) {
          this.alertError(this.genericErrorTextValue)
          return null
        }

        const forms = fieldElements
          .map((field) => this.fieldInput(field)?.form)
          .filter(Boolean)
        const uniqueForms = [...new Set(forms)]

        if (uniqueForms.length !== 1) {
          this.alertError(this.genericErrorTextValue)
          return null
        }

        return uniqueForms[0]
      }

      showClientError (message) {
        const errorMessage = message || this.genericErrorTextValue

        if (!this.isActive || !this.openedPanels) {
          this.alertError(errorMessage)
          return
        }

        this.fieldElements.forEach((field) => {
          this.dispatchToField(field, 'clientError', { message: errorMessage })
        })
      }

      handleTimeout () {
        this.showClientError(window.Folio.Ai.timeoutErrorText(this, this.genericErrorTextValue))
        this.finishLoading()
      }

      startUi () {
        this.stateValue = STATE_LOADING
      }

      finishLoading () {
        this.request.finish()
        this.stateValue = STATE_ACTIVE
      }

      closeUi () {
        this.stateValue = STATE_IDLE
      }

      abortRequest ({ resetUi = true } = {}) {
        this.request.abort()
        this.openedPanels = false

        if (resetUi) this.closeUi()
      }

      fieldForComponentId (componentId) {
        const selector = `.${INPUT_CLASS_NAME}[data-f-ai-input-component-id-value="${window.Folio.Ai.cssEscape(componentId)}"]`

        return this.element.querySelector(selector)
      }

      fieldInput (field) {
        return field.querySelector('[data-f-ai-input-target~="input"]')
      }

      dispatchToField (field, eventName, detail = {}) {
        this.dispatch(eventName, { target: field, detail })
      }

      dispatchStateToChildren () {
        const detail = { state: this.stateValue }
        const selector = [
          '[data-controller~="f-ai-c-text-suggestions-group-controls"]',
          '[data-controller~="f-ai-c-text-suggestions-group-instructions"]'
        ].join(', ')

        this.element.querySelectorAll(selector).forEach((element) => {
          this.dispatch('state', { target: element, detail })
        })
      }

      usesCurrentFormSnapshot (fieldElements) {
        return fieldElements.some((field) => field.dataset.fAiInputCurrentStatePolicyValue === 'current_form_snapshot')
      }

      alertError (message) {
        window.alert(message || this.genericErrorTextValue)
      }

      handleActionEvent (event) {
        if (!event) return

        event.preventDefault()
        if (event.target?.blur) event.target.blur()
      }

      get fieldElements () {
        return Array.from(this.element.querySelectorAll(`.${INPUT_CLASS_NAME}`)).filter((field) => {
          return field.dataset.fAiInputIntegrationKeyValue === this.integrationKeyValue
        })
      }

      get isActive () {
        return this.stateValue !== STATE_IDLE
      }

      get messageBusClientId () {
        return window.MessageBus?.clientId || null
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
      if (message.type !== 'Folio::Ai::BatchTextSuggestionsJob') return
      if (!message.data || !message.data.request_id) return

      const groups = document.querySelectorAll('.f-ai-c-text-suggestions-group')

      for (const group of groups) {
        group.dispatchEvent(new CustomEvent('f-ai-c-text-suggestions-group/message', { detail: { message } }))
      }
    }
  }
})()
