(() => {
  const CONTROLLER_NAME = 'f-ai-c-text-suggestions'
  const BEM_CLASS_NAME = 'f-ai-c-text-suggestions'
  const SELECTED_CLASS = `${BEM_CLASS_NAME}__suggestion--selected`

  const registerTextSuggestionsComponentController = () => {
    window.Folio.Stimulus.register(CONTROLLER_NAME, class extends window.Stimulus.Controller {
      static targets = ['instructions', 'status', 'statusMessage', 'suggestion', 'suggestions']

      static values = {
        integrationKey: String,
        fieldKey: String
      }

      connect () {
        this.markSelectedSuggestion()
      }

      close (event) {
        this.stopActionEvent(event)
        this.dispatch('close', { bubbles: true })
      }

      regenerate (event) {
        this.stopActionEvent(event)

        this.dispatch('regenerate', {
          bubbles: true,
          detail: { instructions: this.hasInstructionsTarget ? this.instructionsTarget.value : '' }
        })
      }

      showClientError (event) {
        const message = event?.detail?.message || ''
        if (!message) return

        this.element.hidden = false
        if (this.hasStatusMessageTarget) this.statusMessageTarget.textContent = message
        if (this.hasStatusTarget) this.statusTarget.hidden = false

        this.suggestionsTargets.forEach((suggestions) => {
          suggestions.hidden = true
        })
      }

      accept (event) {
        this.stopActionEvent(event)

        const suggestion = event.target.closest(`.${BEM_CLASS_NAME}__suggestion`) || event.target

        if (suggestion.classList.contains(SELECTED_CLASS)) {
          this.close()
          return
        }

        this.clearSelection()
        const text = event.params.text || ''
        this.dispatch('accept', { bubbles: true, detail: { text } })
        suggestion.classList.add(SELECTED_CLASS)

        this.dispatch('accepted', { detail: this.trackingDetail() })
      }

      clearSuggestionSelection () {
        this.clearSelection()
      }

      stopPropagation (event) {
        event.stopPropagation()
      }

      clearSelection () {
        this.element.querySelectorAll(`.${SELECTED_CLASS}`).forEach((element) => {
          element.classList.remove(SELECTED_CLASS)
        })
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
      }

      markSelectedSuggestion () {
        const wrap = this.element.closest('.f-ai-input')
        if (!wrap) return

        const input = wrap.querySelector('[data-f-ai-input-target="input"]')
        if (!input) return

        const value = input.value
        if (!value) return

        const suggestion = this.suggestionTargets.find((suggestion) => suggestion.querySelector('.f-ai-c-text-suggestions__suggestion-text').textContent === value)
        if (!suggestion) return

        suggestion.classList.add(SELECTED_CLASS)
      }
    })
  }

  if (window.Folio?.Stimulus?.register && window.Stimulus?.Controller) {
    registerTextSuggestionsComponentController()
  } else {
    document.addEventListener('folio:stimulus-ready', registerTextSuggestionsComponentController, { once: true })
  }
})()
