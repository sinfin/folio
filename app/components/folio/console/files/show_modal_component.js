window.Folio.Stimulus.register('f-c-files-show-modal', class extends window.Stimulus.Controller {
  static values = {
    fileId: { type: String, default: '' },
    loading: { type: Boolean, default: true }
  }

  static targets = ['inner']

  disconnect () {
    this.abortLoad()
  }

  fileIdValueChanged (to, from) {
    if (to === from) return

    if (to) {
      window.Folio.Modal.open(this.element)
    } else {
      window.Folio.Modal.close(this.element)
    }
  }

  abortLoad () {
    if (!this.abortController) return

    this.abortController.abort()
    delete this.abortController
  }

  showFile (e) {
    if (!e.detail.fileId) return
    if (!e.detail.url) return

    this.loadingValue = true
    this.fileIdValue = e.detail.fileId

    this.abortLoad()
    this.abortController = new AbortController()

    window.Folio.Api.apiGet(e.detail.url, null, this.abortController.signal).then((response) => {
      if (response.meta.title) {
        this.element.querySelector('.f-c-ui-modal__title').textContent = response.meta.title
      } else {
        this.element.querySelector('.f-c-ui-modal__title').textContent = ''
      }

      this.innerTarget.innerHTML = response.data.content
      this.loadingValue = false
    }).catch((error) => {
      window.FolioConsole.Flash.alert('Failed to load file ' + error.message)
      this.fileIdValue = ''
      this.loadingValue = false
    })
  }
})
