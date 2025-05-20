window.Folio.Stimulus.register('f-c-files-index-modal', class extends window.Stimulus.Controller {
  static values = {
    fileType: String,
    baseApiUrl: String,
    status: String
  }

  static targets = ['content']

  disconnect () {
    this.abortAjax()
  }

  abortAjax () {
    if (!this.abortController) return

    this.abortController.abort()
    delete this.abortController
  }

  onPickerOpen (e) {
    if (e.detail.picker) {
      this.pickerReference = e.detail.picker
      window.Folio.Modal.open(this.element)
    } else {
      throw new Error('Picker reference is missing in event.detail.picker', e)
    }
  }

  onModalOpened () {
    this.ajax({
      url: this.baseApiUrlValue
    })
  }

  onModalClosed () {
    this.contentTarget.innerHTML = ''
    this.statusValue = 'closed'
  }

  ajax ({ url, data, callback, apiMethod = 'apiGet', status = 'loading' }) {
    this.statusValue = status
    this.abortController = new AbortController()

    window.Folio.Api[apiMethod](url, data, this.abortController.signal).then((res) => {
      if (res && res.data) {
        this.contentTarget.innerHTML = res.data

        if (callback) callback()
      } else {
        throw new Error('Failed to perform modal AJAX request')
      }
    }).catch((error) => {
      const message = error.message || 'An error occurred'
      window.FolioConsole.Flash.alert(message)
    }).finally(() => {
      this.statusValue = 'loaded'
      delete this.abortController
    })
  }
})
