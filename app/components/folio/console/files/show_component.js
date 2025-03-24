//= require folio/confirm

window.Folio.Stimulus.register('f-c-files-show', class extends window.Stimulus.Controller {
  static values = {
    loading: Boolean,
    id: String
  }

  disconnect () {
    this.abortAjaxRequest()
  }

  abortAjaxRequest () {
    if (this.abortController) {
      this.abortController.abort()
      delete this.abortController
    }
  }

  onDestroyClick (e) {
    if (!e || !e.params || !e.params.url) return

    window.Folio.Confirm.confirm(() => {
      this.abortAjaxRequest()
      this.loadingValue = true

      this.abortController = new AbortController()

      window.Folio.Api.apiDelete(e.params.url, null, this.abortController.signal).then(() => {
        this.element.dispatchEvent(new CustomEvent('f-c-files-show/deleted', { bubbles: true, detail: { id: this.idValue } }))
        this.dispatch('deleted')
      }).catch((error) => {
        window.alert(`Could not delete file: ${error.message}`)
      }).finally(() => {
        this.loadingValue = false
        delete this.abortController
      })
    }, 'delete')
  }
})
