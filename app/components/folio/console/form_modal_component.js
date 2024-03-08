window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.FormModal = window.FolioConsole.FormModal || {}

window.FolioConsole.FormModal.open = (data) => {
  document
    .querySelector('.f-c-form-modal')
    .dispatchEvent(new window.CustomEvent('folioConsoleFormModalOpen', { bubbles: true, detail: data }))
}

window.Folio.Stimulus.register('f-c-form-modal', class extends window.Stimulus.Controller {
  static classes = ['loading']

  static targets = ['formWrap']

  disconnect () {
    delete this.triggerReference
  }

  openFromEvent (e) {
    this.formWrapTarget.innerHTML = ''
    this.element.classList.add(this.loadingClass)
    window.Folio.Modal.open(this.element)

    this.triggerReference = e.detail.trigger

    window.Folio.Api.apiHtmlGet(e.detail.modalUrl).then((res) => {
      this.handleResponse(res)
      this.element.classList.remove(this.loadingClass)
    })
  }

  onFormSubmit (e) {
    e.preventDefault()

    if (this.element.classList.contains(this.loadingClass)) return

    this.element.classList.add(this.loadingClass)

    const data = window.Folio.formToHash(e.target)

    window.Folio.Api.apiHtmlPost(e.target.action, { ...data, _ajax: '1' }).then((res) => {
      this.handleResponse(res)
      this.element.classList.remove(this.loadingClass)
    }).catch((err) => {
      window.Folio.Modal.close(this.element)
      window.FolioConsole.Flash.alert(err.message)
    })
  }

  handleResponse (res) {
    if (typeof res === 'string') {
      if (res.startsWith('<!DOCTYPE')) {
        const parser = new window.DOMParser()
        const doc = parser.parseFromString(res, 'text/html')
        const target = doc.querySelector('.f-c-form-modal-target')

        this.formWrapTarget.innerHTML = target.outerHTML
      } else if (res.startsWith('{')) {
        const json = JSON.parse(res)

        if (json && json.data && json.data.success && json.data.state_html) {
          this.triggerReference.closest('.f-c-state').outerHTML = json.data.state_html
          window.Folio.Modal.close(this.element)
          window.Folio.Api.flashMessageFromMeta(json)
        } else {
          throw new Error('Invalid response - JSON missing data/success or data/state_html')
        }
      } else {
        throw new Error('Invalid response - missing DOCTYPE or JSON beginning')
      }
    } else {
      throw new Error('Invalid response - not a string')
    }
  }
})
