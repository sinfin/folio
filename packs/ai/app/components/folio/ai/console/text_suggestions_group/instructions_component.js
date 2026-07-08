(() => {
  const STATE_IDLE = 'idle'
  const STATE_LOADING = 'loading'

  const registerInstructionsController = () => {
    window.Folio.Stimulus.register('f-ai-c-text-suggestions-group-instructions', class extends window.Stimulus.Controller {
      static targets = ['instructions', 'regenerate']

      connect () {
        this.groupState = this.initialGroupState
        this.syncControls()
      }

      regenerate (event) {
        this.handleActionEvent(event)
        if (this.isLoading) return

        this.dispatch('regenerate', {
          bubbles: true,
          detail: { instructions: this.hasInstructionsTarget ? this.instructionsTarget.value : '' }
        })
      }

      onGroupState (event) {
        this.groupState = event?.detail?.state || STATE_IDLE
        this.syncControls()
      }

      syncControls () {
        if (this.hasRegenerateTarget) {
          this.regenerateTarget.disabled = this.isLoading
        }
      }

      handleActionEvent (event) {
        if (!event) return

        event.preventDefault()
        if (event.target?.blur) event.target.blur()
      }

      get groupElement () {
        return this.element.closest('.f-ai-c-text-suggestions-group')
      }

      get initialGroupState () {
        return this.groupElement?.dataset.fAiCTextSuggestionsGroupStateValue || STATE_IDLE
      }

      get isLoading () {
        return this.groupState === STATE_LOADING
      }
    })
  }

  if (window.Folio?.Stimulus?.register && window.Stimulus?.Controller) {
    registerInstructionsController()
  } else {
    document.addEventListener('folio:stimulus-ready', registerInstructionsController, { once: true })
  }
})()
