(() => {
  const registerTextSuggestionsActionsController = () => {
    window.Folio.Stimulus.register('f-ai-c-text-suggestions-actions', class extends window.Stimulus.Controller {
      static targets = ['button', 'undoButton']

      static values = {
        componentId: String
      }

      static classes = ['loading']

      toggle (event) {
        this.stopButtonEvent(event)
        this.dispatch('toggle', { detail: this.eventDetail })
      }

      undo (event) {
        this.stopButtonEvent(event)
        this.dispatch('undo', { detail: this.eventDetail })
      }

      onState (event) {
        if (event.detail?.componentId !== this.componentIdValue) return

        this.buttonTarget.setAttribute('aria-expanded', event.detail.open ? 'true' : 'false')
        this.undoButtonTarget.hidden = !event.detail.undoVisible
        this.element.classList.toggle(this.loadingClass, event.detail.loading)
      }

      stopButtonEvent (event) {
        event.preventDefault()
        event.stopPropagation()
      }

      get eventDetail () {
        return { componentId: this.componentIdValue }
      }
    })
  }

  if (window.Folio?.Stimulus?.register && window.Stimulus?.Controller) {
    registerTextSuggestionsActionsController()
  } else {
    document.addEventListener('folio:stimulus-ready', registerTextSuggestionsActionsController, { once: true })
  }
})()
