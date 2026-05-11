(() => {
  const CONTROLLER_NAME = 'f-ai-c-text-suggestions'
  const BEM_CLASS_NAME = 'f-ai-c-text-suggestions'
  const SELECTED_CLASS = `${BEM_CLASS_NAME}__suggestion--selected`

  const registerTextSuggestionsComponentController = () => {
    window.Folio.Stimulus.register(CONTROLLER_NAME, class extends window.Stimulus.Controller {
      static targets = ['instructions']

      static values = {
        integrationKey: String,
        fieldKey: String
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

      accept (event) {
        this.stopActionEvent(event)

        const text = event.params.text || ''
        this.dispatch('accept', { bubbles: true, detail: { text } })
        this.markSelected(event.currentTarget)

        this.dispatch('accepted', { detail: this.trackingDetail() })
      }

      acceptFromKeyboard (event) {
        if (!['Enter', ' '].includes(event.key)) return

        this.accept(event)
      }

      clearSuggestionSelection () {
        this.clearSelection()
      }

      stopPropagation (event) {
        event.stopPropagation()
      }

      markSelected (selectedElement) {
        this.clearSelection()

        const suggestion = selectedElement.closest(`.${BEM_CLASS_NAME}__suggestion`) || selectedElement
        suggestion.classList.add(SELECTED_CLASS)
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
    })
  }

  if (window.Folio?.Stimulus?.register && window.Stimulus?.Controller) {
    registerTextSuggestionsComponentController()
  } else {
    document.addEventListener('folio:stimulus-ready', registerTextSuggestionsComponentController, { once: true })
  }
})()
