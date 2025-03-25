window.Folio.Stimulus.register('f-c-files-show-modal', class extends window.Stimulus.Controller {
  static values = {
    id: { type: String, default: '' },
    url: { type: String, default: '' },
    loading: { type: Boolean, default: true }
  }

  static targets = ['inner']

  disconnect () {
    this.abortLoad()
  }

  idValueChanged (to, from) {
    if (to === from) return

    if (to) {
      window.Folio.Modal.open(this.element)
    } else {
      window.Folio.Modal.close(this.element)
    }
  }

  onModalClosed () {
    this.element.querySelector('.f-c-ui-modal__title').textContent = ''
    this.innerTarget.innerHTML = ''
    this.idValue = ''
    this.urlValue = ''
  }

  abortLoad () {
    if (!this.abortController) return

    this.abortController.abort()
    delete this.abortController
  }

  onShowFile (e) {
    this.showFile({ id: e.detail.id, url: e.detail.url })
  }

  showFile ({ id, url }) {
    if (!id || !url) return

    this.loadingValue = true
    this.idValue = id
    this.urlValue = url

    this.abortLoad()
    this.abortController = new AbortController()

    window.Folio.Api.apiGet(url, null, this.abortController.signal).then((response) => {
      if (response.meta.title) {
        this.element.querySelector('.f-c-ui-modal__title').textContent = response.meta.title
      } else {
        this.element.querySelector('.f-c-ui-modal__title').textContent = ''
      }

      this.innerTarget.innerHTML = response.data
      this.loadingValue = false
    }).catch((error) => {
      window.FolioConsole.Flash.alert('Failed to load file ' + error.message)
      this.idValue = ''
      this.loadingValue = false
    })
  }

  onFileDeleted (e) {
    this.idValue = ''
    this.loadingValue = false
  }
})
