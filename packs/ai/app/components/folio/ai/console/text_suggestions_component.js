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
        'panel',
        'status',
        'suggestions',
        'instructions'
      ]

      static values = {
        endpoint: String,
        integrationKey: String,
        fieldKey: String,
        suggestionCount: { type: Number, default: 3 },
        characterLimit: Number,
        initialInstructions: { type: String, default: '' },
        fieldLabel: String,
        buttonLabel: String,
        undoLabel: String,
        closeLabel: String,
        panelTitle: String,
        loadingText: String,
        genericErrorText: String,
        requestTimeoutText: String,
        requestTimeoutMs: { type: Number, default: 45000 },
        missingContextText: String,
        copyLabel: String,
        copyButtonLabel: String,
        acceptLabel: String,
        acceptButtonLabel: String,
        charsLabel: String,
        instructionsPlaceholder: String,
        regenerateLabel: String,
        componentId: String,
        currentStatePolicy: { type: String, default: 'persisted_record' },
        showMeta: { type: Boolean, default: false },
        sparklesPath: String,
        undoPath: String
      }

      connect () {
        if (!this.input) return

        this.mount()
        this.snapshot = null
        this.selectedText = null
        this.requestSequence = 0
        this.requestTimeoutId = null
        this.requestTimedOut = false
        this.undoVisible = false
        this.savedInstructions = this.initialInstructionsValue
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
        this.suggestionsTarget.innerHTML = ''
        this.hideStatus()
        this.element.classList.remove(OPEN_CLASS)
        this.element.classList.remove(LOADING_CLASS)
        this.undoVisible = false
        this.instructionsTarget.value = this.savedInstructions

        if (openController === this) openController = null

        this.syncControls()
      }

      regenerate (event) {
        event.preventDefault()
        event.stopPropagation()

        if (!this.isOpen) this.showPanel()

        this.generate({ persistInstructions: true })
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

      generate ({ persistInstructions }) {
        const requestId = this.nextRequestId()
        this.abortRequest()
        this.abortController = new AbortController()
        this.requestTimedOut = false
        this.setRequestTimeout(requestId)
        this.setLoading()

        window.Folio.Api.apiPost(this.endpointValue, this.requestPayload(persistInstructions), this.abortController.signal)
          .then((response) => {
            if (this.staleRequest(requestId)) return

            this.handleSuccess(response, { persistInstructions })
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

      requestPayload (persistInstructions) {
        const payload = {
          integration_key: this.integrationKeyValue,
          field_key: this.fieldKeyValue,
          instructions: this.instructionsTarget.value,
          persist_instructions: persistInstructions,
          suggestion_count: this.suggestionCountValue
        }

        if (this.usesCurrentFormSnapshot) {
          payload.current_form_snapshot = this.currentFormSnapshot()
        }

        return payload
      }

      handleSuccess (response, { persistInstructions }) {
        if (response.error_code || response.error || response.code) {
          this.handleError({ responseData: response })
          return
        }

        const data = response.data || response
        const suggestions = data.suggestions || []
        const warnings = data.warnings || []

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

        this.renderSuggestions(suggestions)
        this.showWarnings(warnings)
      }

      handleError (error) {
        this.suggestionsTarget.innerHTML = ''
        this.showError(this.errorMessage(error))
      }

      handleTimeout () {
        this.handleError({
          responseData: {
            error_code: 'client_timeout',
            message: this.timeoutErrorText()
          }
        })
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
        const element = document.createElement('div')
        element.className = `${BEM_CLASS_NAME}__suggestion`
        element.setAttribute('role', 'button')
        element.setAttribute('tabindex', '0')
        element.setAttribute('data-action', `click->${CONTROLLER_NAME}#accept keydown->${CONTROLLER_NAME}#acceptFromKeyboard`)
        element.setAttribute(`data-${CONTROLLER_NAME}-text-param`, suggestion.text || '')
        element.setAttribute(`data-${CONTROLLER_NAME}-key-param`, suggestion.key || '')

        const body = document.createElement('span')
        body.className = `${BEM_CLASS_NAME}__suggestion-body`
        if (this.showMetaValue) body.appendChild(this.suggestionMetaElement(suggestion))
        body.appendChild(this.suggestionTextElement(suggestion.text || ''))

        const actions = document.createElement('span')
        actions.className = `${BEM_CLASS_NAME}__suggestion-actions`
        actions.appendChild(this.actionButton('copy',
          this.copyButtonLabelValue,
          this.copyLabelValue,
          suggestion.text || ''))
        actions.appendChild(this.actionButton('accept',
          this.acceptButtonLabelValue,
          this.acceptLabelValue,
          suggestion.text || ''))

        element.appendChild(body)
        element.appendChild(actions)

        return element
      }

      suggestionMetaElement (suggestion) {
        const meta = document.createElement('span')
        meta.className = `${BEM_CLASS_NAME}__suggestion-meta`

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
        span.className = `${BEM_CLASS_NAME}__suggestion-text`
        span.textContent = text
        return span
      }

      actionButton (action, buttonLabel, label, text) {
        const button = document.createElement('button')
        button.type = 'button'
        button.className = `${BEM_CLASS_NAME}__suggestion-${action}`
        button.textContent = buttonLabel
        button.setAttribute('aria-label', label)
        button.setAttribute('title', label)
        button.setAttribute('data-action', `click->${CONTROLLER_NAME}#${action}`)
        button.setAttribute(`data-${CONTROLLER_NAME}-text-param`, text)
        return button
      }

      setLoading () {
        this.element.classList.add(LOADING_CLASS)
        this.syncControls()
        this.hideStatus()
        this.suggestionsTarget.innerHTML = ''

        for (let i = 0; i < this.suggestionCountValue; i += 1) {
          const item = document.createElement('div')
          item.className = `${BEM_CLASS_NAME}__suggestion ${BEM_CLASS_NAME}__suggestion--loading`
          item.textContent = this.loadingTextValue
          this.suggestionsTarget.appendChild(item)
        }
      }

      showPanel () {
        this.panelTarget.hidden = false
        this.element.classList.add(OPEN_CLASS)
        this.syncControls()
      }

      showError (message) {
        this.panelTarget.classList.add(`${BEM_CLASS_NAME}__panel--error`)
        this.statusTarget.hidden = false
        this.statusTarget.textContent = message
      }

      showWarnings (warnings) {
        const messages = warnings.map((warning) => warning.message).filter((message) => message)

        if (messages.length === 0) {
          this.hideStatus()
          return
        }

        this.panelTarget.classList.remove(`${BEM_CLASS_NAME}__panel--error`)
        this.statusTarget.hidden = false
        this.statusTarget.textContent = messages.join(' ')
      }

      hideStatus () {
        this.panelTarget.classList.remove(`${BEM_CLASS_NAME}__panel--error`)
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

        const suggestion = selectedElement.closest(`.${BEM_CLASS_NAME}__suggestion`) || selectedElement
        suggestion.classList.add(`${BEM_CLASS_NAME}__suggestion--selected`)
      }

      clearSelection () {
        this.suggestionsTarget.querySelectorAll(`.${BEM_CLASS_NAME}__suggestion--selected`).forEach((element) => {
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

        this.buttonTarget.setAttribute('aria-expanded', this.isOpen ? 'true' : 'false')
        this.undoButtonTarget.hidden = !this.undoVisible
        this.controlsElement?.classList.toggle(OPEN_CLASS, this.isOpen)
        this.controlsElement?.classList.toggle(LOADING_CLASS, loading)
      }

      mount () {
        this.mountControls()
        this.mountPanel()
      }

      mountControls () {
        if (this.hasButtonTarget && this.hasUndoButtonTarget) return

        const controls = document.createElement('div')
        controls.className = `${BEM_CLASS_NAME} ${BEM_CLASS_NAME}__actions`

        const button = document.createElement('button')
        button.type = 'button'
        button.id = `${this.componentIdValue}_button`
        button.className = `${BEM_CLASS_NAME}__button`
        button.setAttribute('aria-expanded', 'false')
        button.setAttribute('aria-controls', this.componentIdValue)
        button.setAttribute('data-action', `click->${CONTROLLER_NAME}#toggle`)
        button.setAttribute(`data-${CONTROLLER_NAME}-target`, 'button')
        button.appendChild(this.iconElement('sparkles'))
        button.appendChild(this.labelElement(`${BEM_CLASS_NAME}__button-label`, this.buttonLabelValue))

        const undoButton = document.createElement('button')
        undoButton.type = 'button'
        undoButton.id = `${this.componentIdValue}_undo`
        undoButton.className = `${BEM_CLASS_NAME}__undo`
        undoButton.hidden = true
        undoButton.setAttribute('data-action', `click->${CONTROLLER_NAME}#undo`)
        undoButton.setAttribute(`data-${CONTROLLER_NAME}-target`, 'undoButton')
        undoButton.appendChild(this.iconElement('undo'))
        undoButton.appendChild(this.labelElement(`${BEM_CLASS_NAME}__undo-label`, this.undoLabelValue))

        controls.appendChild(button)
        controls.appendChild(undoButton)
        this.insertControls(controls)
      }

      insertControls (controls) {
        const label = this.input.id
          ? Array.from(this.element.querySelectorAll('label')).find((label) => label.htmlFor === this.input.id)
          : null
        const insertionTarget = label || this.element.querySelector('label')

        if (insertionTarget) {
          insertionTarget.insertAdjacentElement('afterend', controls)
        } else {
          this.element.insertBefore(controls, this.element.firstChild)
        }
      }

      mountPanel () {
        if (this.hasPanelTarget) return

        const panel = document.createElement('div')
        panel.id = this.componentIdValue
        panel.className = `${BEM_CLASS_NAME}__panel`
        panel.hidden = true
        panel.setAttribute('role', 'region')
        panel.setAttribute('aria-label', this.panelTitleValue)
        panel.setAttribute(`data-${CONTROLLER_NAME}-target`, 'panel')
        panel.setAttribute('data-action', `click->${CONTROLLER_NAME}#stopPropagation`)

        panel.appendChild(this.panelHeaderElement())
        panel.appendChild(this.statusElement())
        panel.appendChild(this.suggestionsElement())
        panel.appendChild(this.instructionsElement())

        this.insertPanel(panel)
      }

      insertPanel (panel) {
        const inputGroup = this.input.closest('.input-group')
        const anchor = inputGroup && this.element.contains(inputGroup) ? inputGroup : this.input
        anchor.insertAdjacentElement('afterend', panel)
      }

      panelHeaderElement () {
        const header = document.createElement('div')
        header.className = `${BEM_CLASS_NAME}__header`

        const title = document.createElement('div')
        title.className = `${BEM_CLASS_NAME}__title`
        title.textContent = this.panelTitleValue

        const closeButton = document.createElement('button')
        closeButton.type = 'button'
        closeButton.className = `${BEM_CLASS_NAME}__close`
        closeButton.setAttribute('aria-label', this.closeLabelValue)
        closeButton.setAttribute('data-action', `click->${CONTROLLER_NAME}#close`)
        closeButton.textContent = '\u00d7'

        header.appendChild(title)
        header.appendChild(closeButton)

        return header
      }

      statusElement () {
        const status = document.createElement('div')
        status.className = `${BEM_CLASS_NAME}__status`
        status.hidden = true
        status.setAttribute(`data-${CONTROLLER_NAME}-target`, 'status')
        return status
      }

      suggestionsElement () {
        const suggestions = document.createElement('div')
        suggestions.className = `${BEM_CLASS_NAME}__suggestions`
        suggestions.setAttribute(`data-${CONTROLLER_NAME}-target`, 'suggestions')
        return suggestions
      }

      instructionsElement () {
        const instructions = document.createElement('div')
        instructions.className = `${BEM_CLASS_NAME}__instructions`

        const textarea = document.createElement('textarea')
        textarea.className = `${BEM_CLASS_NAME}__instructions-input`
        textarea.rows = 2
        textarea.placeholder = this.instructionsPlaceholderValue
        textarea.value = this.initialInstructionsValue
        textarea.setAttribute(`data-${CONTROLLER_NAME}-target`, 'instructions')

        const regenerate = document.createElement('button')
        regenerate.type = 'button'
        regenerate.className = `${BEM_CLASS_NAME}__regenerate`
        regenerate.setAttribute('data-action', `click->${CONTROLLER_NAME}#regenerate`)
        regenerate.textContent = this.regenerateLabelValue

        instructions.appendChild(textarea)
        instructions.appendChild(regenerate)

        return instructions
      }

      iconElement (icon) {
        const isUndo = icon === 'undo'
        const wrapper = document.createElement('span')
        wrapper.className = isUndo ? `${BEM_CLASS_NAME}__undo-icon` : `${BEM_CLASS_NAME}__spark`
        wrapper.setAttribute('aria-hidden', 'true')

        const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
        svg.setAttribute('class', isUndo ? `${BEM_CLASS_NAME}__undo-svg` : `${BEM_CLASS_NAME}__spark-svg`)
        svg.setAttribute('fill', 'none')
        svg.setAttribute('viewBox', '0 0 24 24')
        svg.setAttribute('xmlns', 'http://www.w3.org/2000/svg')

        const path = document.createElementNS('http://www.w3.org/2000/svg', 'path')
        path.setAttribute('d', isUndo ? this.undoPathValue : this.sparklesPathValue)
        path.setAttribute('fill', 'currentColor')

        svg.appendChild(path)
        wrapper.appendChild(svg)

        return wrapper
      }

      labelElement (className, text) {
        const label = document.createElement('span')
        label.className = className
        label.textContent = text
        return label
      }

      get input () {
        return this.hasInputTarget ? this.inputTarget : null
      }

      get controlsElement () {
        return this.hasButtonTarget ? this.buttonTarget.closest(`.${BEM_CLASS_NAME}`) : null
      }

      get isOpen () {
        return this.hasPanelTarget && !this.panelTarget.hidden
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
