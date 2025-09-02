window.Folio.Stimulus.register('f-c-tiptap-simple-form-wrap-unsaved-changes', class extends window.Stimulus.Controller {
  onContinueButtonClick () {
    this.element.style.display = 'none'
    this.dispatch('continueUnsavedChanges', { bubbles: true })
  }

  onDiscardButtonClick () {

  }
})
