window.Folio.Stimulus.register('f-c-tiptap-simple-form-wrap-autosave-info', class extends window.Stimulus.Controller {
  static values = {
    placementType: String,
    placementId: Number,
    deleteUrl: String,
  }

  static targets = ['unsavedChanges', 'failedToSave']

  onContinueButtonClick () {
    this.hideUnsavedChanges()
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

  hideUnsavedChanges () {
    if (this.hasUnsavedChangesTarget) {
      this.unsavedChangesTarget.style.display = 'none'
    }
  }

  showFailedToSave () {
    this.failedToSaveTarget.classList.remove('f-c-tiptap-simple-form-wrap-autosave-info__failed-to-save--hidden')
  }

  hideFailedToSave () {
    this.failedToSaveTarget.classList.add('f-c-tiptap-simple-form-wrap-autosave-info__failed-to-save--hidden')
  }
})
