(() => {
  const STATE_IDLE = 'idle'
  const STATE_LOADING = 'loading'

  const registerControlsController = () => {
    window.Folio.Stimulus.register('f-ai-c-text-suggestions-group-controls', class extends window.Stimulus.Controller {
      static targets = ['button', 'close']

      connect () {
        this.groupState = this.initialGroupState
        this.syncControls()
      }

      generate (event) {
        this.handleActionEvent(event)
        if (this.isLoading) return

        this.dispatch('generate', { bubbles: true })
      }

      close (event) {
        this.handleActionEvent(event)

        this.dispatch('close', { bubbles: true })
      }

      onGroupState (event) {
        this.groupState = event?.detail?.state || STATE_IDLE
        this.syncControls()
      }

      syncControls () {
        if (this.hasButtonTarget) {
          this.buttonTarget.disabled = this.isLoading
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
    registerControlsController()
  } else {
    document.addEventListener('folio:stimulus-ready', registerControlsController, { once: true })
  }
})()
