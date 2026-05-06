(() => {
  const CONTROLLER_NAME = 'f-input-ai-text-suggestions'
  const BEM_CLASS_NAME = 'f-ai-c-text-suggestions'
  const OPEN_CLASS = `${BEM_CLASS_NAME}--open`
  const LOADING_CLASS = `${BEM_CLASS_NAME}--loading`
  let openController = null

  const registerInputAiTextSuggestionsController = () => {
    window.Folio.Stimulus.register(CONTROLLER_NAME, class extends window.Stimulus.Controller {
      static targets = [
        'input',
        'button',
        'undoButton',
        'customHtml',
        'component',
        'instructions'
      ]

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
        if (!this.input || !this.hasCustomHtmlTarget) return

        this.snapshot = null
        this.selectedText = null
        this.requestSequence = 0
        this.requestTimeoutId = null
        this.requestTimedOut = false
        this.undoVisible = false
        this.targetInputListener = () => this.onTargetInput()
        this.input.addEventListener('input', this.targetInputListener)
        this.syncControls()
      }

      disconnect () {
        this.abortRequest()
        this.input?.removeEventListener('input', this.targetInputListener)

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
        const input = this.input
        if (!input) return

        if (openController && openController !== this) openController.close()
        openController = this

        this.snapshot = input.value || ''
        this.selectedText = null
        this.clearSelection()
        this.loadHtml({ method: 'GET' })
      }

      close (event) {
        if (event) {
          event.preventDefault()
          event.stopPropagation()
        }

        this.abortRequest()
        this.snapshot = null
        this.selectedText = null
        this.customHtmlTarget.innerHTML = ''
        this.element.classList.remove(OPEN_CLASS)
        this.element.classList.remove(LOADING_CLASS)
        this.undoVisible = false

        if (openController === this) openController = null

        this.syncControls()
      }

      regenerate (event) {
        event.preventDefault()
        event.stopPropagation()

        this.loadHtml({ method: 'POST' })
      }

      undo (event) {
        this.stopActionEvent(event)

        if (this.snapshot === null) return
        if (!this.input) return

        this.writeValue(this.input, this.snapshot)
        this.selectedText = null
        this.clearSelection()
        this.undoVisible = false
        this.syncControls()

        this.dispatch('undo', { detail: this.trackingDetail() })
      }

      accept (event) {
        event.preventDefault()
        event.stopPropagation()

        if (!this.input) return

        const text = event.params.text || ''
        this.selectedText = text
        this.writeValue(this.input, text)
        this.markSelected(event.currentTarget)
        this.undoVisible = true
        this.syncControls()

        this.dispatch('accepted', { detail: this.trackingDetail() })
      }

      acceptFromKeyboard (event) {
        if (!['Enter', ' '].includes(event.key)) return

        this.accept(event)
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
        if (!this.input || this.input.value === this.selectedText) return

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

      stopPropagation (event) {
        event.stopPropagation()
      }

      loadHtml ({ method }) {
        const requestId = this.nextRequestId()
        const body = this.requestPayload({ includeInstructions: method === 'POST' })
        this.abortRequest()
        this.abortController = new AbortController()
        this.requestTimedOut = false
        this.setRequestTimeout(requestId)
        this.setLoading()

        const request = method === 'POST'
          ? window.Folio.Api.apiHtmlPost(this.instructionsUrlValue, body, this.abortController.signal)
          : window.Folio.Api.apiHtmlGet(this.urlWithParams(this.urlValue, body), null, this.abortController.signal)

        request
          .then((html) => {
            if (this.staleRequest(requestId)) return

            this.handleHtml(html)
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
            this.element.classList.remove(LOADING_CLASS)
            this.syncControls()
          })
      }

      requestPayload ({ includeInstructions }) {
        const payload = {
          klass: this.klassValue,
          id: this.recordIdValue,
          integration_key: this.integrationKeyValue,
          field_key: this.fieldKeyValue,
          component_id: this.componentIdValue,
          show_meta: this.showMetaValue,
          suggestion_count: this.suggestionCountValue
        }

        if (includeInstructions) {
          payload.instructions = this.hasInstructionsTarget ? this.instructionsTarget.value : ''
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
        this.element.classList.add(OPEN_CLASS)
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
        this.element.classList.add(LOADING_CLASS)
        this.element.classList.add(OPEN_CLASS)
        this.customHtmlTarget.replaceChildren(this.loadingElement())
        this.syncControls()
      }

      loadingElement () {
        const wrapper = document.createElement('div')
        wrapper.className = `${BEM_CLASS_NAME} ${OPEN_CLASS} ${LOADING_CLASS}`

        const panel = document.createElement('div')
        panel.className = `${BEM_CLASS_NAME}__panel`
        panel.setAttribute('role', 'region')
        panel.setAttribute('aria-label', this.loadingTextValue)

        const suggestions = document.createElement('div')
        suggestions.className = `${BEM_CLASS_NAME}__suggestions`

        for (let i = 0; i < this.suggestionCountValue; i += 1) {
          const item = document.createElement('div')
          item.className = `${BEM_CLASS_NAME}__suggestion ${BEM_CLASS_NAME}__suggestion--loading`
          item.textContent = this.loadingTextValue
          suggestions.appendChild(item)
        }

        panel.appendChild(suggestions)
        wrapper.appendChild(panel)

        return wrapper
      }

      showClientError (message) {
        const wrapper = document.createElement('div')
        wrapper.className = `${BEM_CLASS_NAME} ${OPEN_CLASS}`

        const panel = document.createElement('div')
        panel.className = `${BEM_CLASS_NAME}__panel ${BEM_CLASS_NAME}__panel--error`

        const status = document.createElement('div')
        status.className = `${BEM_CLASS_NAME}__status`
        status.textContent = message

        panel.appendChild(status)
        wrapper.appendChild(panel)
        this.customHtmlTarget.replaceChildren(wrapper)
      }

      writeValue (input, value) {
        input.value = value
        input.dispatchEvent(new Event('input', { bubbles: true }))
        input.dispatchEvent(new Event('change', { bubbles: true }))
        input.dispatchEvent(new CustomEvent('folioConsoleCustomChange', { bubbles: true }))
      }

      markSelected (selectedElement) {
        this.clearSelection()

        const suggestion = selectedElement.closest(`.${BEM_CLASS_NAME}__suggestion`) || selectedElement
        suggestion.classList.add(`${BEM_CLASS_NAME}__suggestion--selected`)
      }

      clearSelection () {
        this.customHtmlTarget.querySelectorAll(`.${BEM_CLASS_NAME}__suggestion--selected`).forEach((element) => {
          element.classList.remove(`${BEM_CLASS_NAME}__suggestion--selected`)
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

      trackingDetail () {
        return {
          integrationKey: this.integrationKeyValue,
          fieldKey: this.fieldKeyValue
        }
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

      stopActionEvent (event) {
        if (!event) return

        event.preventDefault()
        event.stopPropagation()
      }

      syncControls () {
        const loading = this.element.classList.contains(LOADING_CLASS)

        if (this.hasButtonTarget) {
          this.buttonTarget.setAttribute('aria-expanded', this.isOpen ? 'true' : 'false')
        }

        if (this.hasUndoButtonTarget) {
          this.undoButtonTarget.hidden = !this.undoVisible
        }

        this.controlsElement?.classList.toggle(OPEN_CLASS, this.isOpen)
        this.controlsElement?.classList.toggle(LOADING_CLASS, loading)
      }

      get input () {
        return this.hasInputTarget ? this.inputTarget : null
      }

      get controlsElement () {
        return this.hasButtonTarget ? this.buttonTarget.closest('.f-input-ai-text-suggestions__actions') : null
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
    registerInputAiTextSuggestionsController()
  } else {
    document.addEventListener('folio:stimulus-ready', registerInputAiTextSuggestionsController, { once: true })
  }
})()
