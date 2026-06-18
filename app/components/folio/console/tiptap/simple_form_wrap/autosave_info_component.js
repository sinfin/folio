window.Folio.Stimulus.register('f-c-tiptap-simple-form-wrap-autosave-info', class extends window.Stimulus.Controller {
  static values = {
    placementType: String,
    placementId: Number,
    takeoverUrl: String,
    deleteRevisionUrl: String,
    fromUserId: Number,
    attributeName: String
  }

  static targets = ['unsavedChanges', 'failedToSave']

  onContinueButtonClick () {
    this.hideUnsavedChanges()
    this.dispatch('continueUnsavedChanges', { bubbles: true })
  }

  onDiscardButtonClick () {
    const data = {
      from_user_id: this.fromUserIdValue,
      placement: {
        type: this.placementTypeValue,
        id: this.placementIdValue,
        attribute_name: this.attributeNameValue || 'tiptap_content'
      }
    }

    window.Folio.Api.apiPost(this.takeoverUrlValue, data).then(() => {
      window.location.reload()
    }).catch((err) => {
      console.error('Takeover failed:', err)
    })
  }

  onReloadButtonClick () {
    const data = {
      from_user_id: this.fromUserIdValue,
      placement: {
        type: this.placementTypeValue,
        id: this.placementIdValue,
        attribute_name: this.attributeNameValue || 'tiptap_content'
      }
    }

    window.Folio.Api.apiDelete(this.deleteRevisionUrlValue, data).then(() => {
      window.location.reload()
    }).catch((err) => {
      console.error('Deleting revision failed:', err)
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
