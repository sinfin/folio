window.Folio.Stimulus.register('f-c-tiptap-simple-form-wrap-unsaved-changes', class extends window.Stimulus.Controller {
  static values = {
    placementType: String,
    placementId: Number,
    deleteUrl: String,
  }

  onContinueButtonClick () {
    this.element.style.display = 'none'
    this.dispatch('continueUnsavedChanges', { bubbles: true })
  }

  onDiscardButtonClick () {
    const data = {
      placement: {
        type: this.placementTypeValue,
        id: this.placementIdValue
      }
    }

    window.Folio.Api.apiDelete(this.deleteUrlValue, data)
      .then((response) => {
        if (response && response.success) {
          window.location.reload()
        }
      })
      .catch((error) => {
        console.warn('[Folio] [Tiptap] Discard failed:', error)
      })
  }
})
