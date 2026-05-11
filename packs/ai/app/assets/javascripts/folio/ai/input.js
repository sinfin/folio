(() => {
  const CONTROLLER_NAME = 'f-ai-input'
  const INPUT_CLASS_NAME = 'f-ai-input'
  const INPUT_OPEN_CLASS = `${INPUT_CLASS_NAME}--open`
  const INPUT_LOADING_CLASS = `${INPUT_CLASS_NAME}--loading`
  const CONTROLS_OPEN_CLASS = `${INPUT_CLASS_NAME}__controls--open`
  const CONTROLS_LOADING_CLASS = `${INPUT_CLASS_NAME}__controls--loading`
  const PANEL_CLASS_NAME = 'f-ai-c-text-suggestions'
  const PANEL_OPEN_CLASS = `${PANEL_CLASS_NAME}--open`
  const PANEL_LOADING_CLASS = `${PANEL_CLASS_NAME}--loading`
  let openController = null

  const registerAiInputController = () => {
    window.Folio.Stimulus.register(CONTROLLER_NAME, class extends window.Stimulus.Controller {
      static targets = ['input', 'button', 'customHtml']

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
        requestTimeoutText: String
      }

      connect () {
        this.requestSequence = 0
        this.requestTimeoutId = null
        this.requestTimedOut = false
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
        this.loadHtml({ method: 'GET' })
      }

      close (event) {
        this.stopActionEvent(event)
        this.abortRequest()
        this.customHtmlTarget.innerHTML = ''
        this.element.classList.remove(INPUT_OPEN_CLASS)
        this.element.classList.remove(INPUT_LOADING_CLASS)
        this.clearSession()

        if (openController === this) openController = null

        this.syncControls()
      }

      regenerate (event) {
        this.stopActionEvent(event)
        this.loadHtml({
          method: 'POST',
          instructions: event?.detail?.instructions || ''
        })
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

      loadHtml ({ method, instructions = null }) {
        const requestId = this.nextRequestId()
        const body = this.requestPayload({ instructions })
        this.abortRequest()
        this.abortController = new AbortController()
        this.requestTimedOut = false
        this.setRequestTimeout(requestId)
        this.setLoading()

        const request = method === 'POST'
          ? window.Folio.Api.apiPost(this.instructionsUrlValue, body, this.abortController.signal)
          : window.Folio.Api.apiGet(this.urlWithParams(this.urlValue, body), null, this.abortController.signal)

        request
          .then((response) => {
            if (this.staleRequest(requestId)) return

            this.handleHtml(response.data)
          })
          .catch((error) => {
            if (this.staleRequest(requestId)) return

            if (error.name === 'AbortError') {
              if (this.requestTimedOut) this.handleTimeout()
              return
            }

            this.handleError(error)
          })
          .finally(() => {
            if (this.staleRequest(requestId)) return

            this.clearRequestTimeout()
            this.abortController = null
            this.requestTimedOut = false
            this.element.classList.remove(INPUT_LOADING_CLASS)
            this.syncControls()
          })
      }

      requestPayload ({ instructions }) {
        const payload = {
          klass: this.klassValue,
          id: this.recordIdValue,
          integration_key: this.integrationKeyValue,
          field_key: this.fieldKeyValue,
          component_id: this.componentIdValue,
          target_input_id: this.input?.id,
          show_meta: this.showMetaValue,
          suggestion_count: this.suggestionCountValue
        }

        if (instructions !== null) {
          payload.instructions = instructions
        }

        if (this.usesCurrentFormSnapshot) {
          payload.current_form_snapshot_json = JSON.stringify(this.currentFormSnapshot())
        }

        return payload
      }

      urlWithParams (url, payload) {
        const urlObject = new URL(url, window.location.origin)

        Object.entries(payload).forEach(([key, value]) => {
          if (value === null || typeof value === 'undefined') return

          urlObject.searchParams.set(key, value)
        })

        return `${urlObject.pathname}${urlObject.search}${urlObject.hash}`
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

      setLoading () {
        this.element.classList.add(INPUT_LOADING_CLASS)
        this.element.classList.add(INPUT_OPEN_CLASS)
        this.customHtmlTarget.replaceChildren(this.loadingElement())
        this.syncControls()
      }

      loadingElement () {
        const wrapper = document.createElement('div')
        wrapper.className = `${PANEL_CLASS_NAME} ${PANEL_OPEN_CLASS} ${PANEL_LOADING_CLASS}`

        const panel = document.createElement('div')
        panel.className = `${PANEL_CLASS_NAME}__panel`
        panel.setAttribute('role', 'region')
        panel.setAttribute('aria-label', this.loadingTextValue)

        const suggestions = document.createElement('div')
        suggestions.className = `${PANEL_CLASS_NAME}__suggestions`

        for (let i = 0; i < this.suggestionCountValue; i += 1) {
          const item = document.createElement('div')
          item.className = `${PANEL_CLASS_NAME}__suggestion ${PANEL_CLASS_NAME}__suggestion--loading`
          item.textContent = this.loadingTextValue
          suggestions.appendChild(item)
        }

        panel.appendChild(suggestions)
        wrapper.appendChild(panel)

        return wrapper
      }

      showClientError (message) {
        const wrapper = document.createElement('div')
        wrapper.className = `${PANEL_CLASS_NAME} ${PANEL_OPEN_CLASS}`

        const panel = document.createElement('div')
        panel.className = `${PANEL_CLASS_NAME}__panel ${PANEL_CLASS_NAME}__panel--error`

        const status = document.createElement('div')
        status.className = `${PANEL_CLASS_NAME}__status`
        status.textContent = message

        panel.appendChild(status)
        wrapper.appendChild(panel)
        this.customHtmlTarget.replaceChildren(wrapper)
      }

      nextRequestId () {
        this.requestSequence += 1
        return this.requestSequence
      }

      staleRequest (requestId) {
        return requestId !== this.requestSequence
      }

      abortRequest () {
        this.clearRequestTimeout()
        this.requestTimedOut = false

        if (!this.abortController) return

        this.abortController.abort()
        this.abortController = null
      }

      setRequestTimeout (requestId) {
        if (this.requestTimeoutMsValue <= 0) return

        this.requestTimeoutId = window.setTimeout(() => {
          if (this.staleRequest(requestId) || !this.abortController) return

          this.requestTimedOut = true
          this.abortController.abort()
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
        const undoButton = this.element.querySelector('.f-ai-input__undo')

        if (undoButton) {
          undoButton.hidden = true
        }
      }

      stopActionEvent (event) {
        if (!event) return

        event.preventDefault()
        event.stopPropagation()
      }

      syncControls () {
        const loading = this.element.classList.contains(INPUT_LOADING_CLASS)

        if (this.hasButtonTarget) {
          this.buttonTarget.setAttribute('aria-expanded', this.isOpen ? 'true' : 'false')
        }

        this.controlsElement?.classList.toggle(CONTROLS_OPEN_CLASS, this.isOpen)
        this.controlsElement?.classList.toggle(CONTROLS_LOADING_CLASS, loading)
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

      get usesCurrentFormSnapshot () {
        return this.currentStatePolicyValue === 'current_form_snapshot'
      }
    })
  }

  if (window.Folio?.Stimulus?.register && window.Stimulus?.Controller) {
    registerAiInputController()
  } else {
    document.addEventListener('folio:stimulus-ready', registerAiInputController, { once: true })
  }
})()
