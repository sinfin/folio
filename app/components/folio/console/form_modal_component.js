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

    this.updateTitle(e.detail.title)
    this.triggerReference = e.detail.trigger

    window.Folio.Api.apiHtmlGet(e.detail.url).then((res) => {
      this.handleResponse(res)
      if (!e.detail.title) this.tryToGetTitleFromH1()
      this.element.classList.remove(this.loadingClass)
    })
  }

  onFormSubmit (e) {
    e.preventDefault()

    if (this.element.classList.contains(this.loadingClass)) return

    this.element.classList.add(this.loadingClass)

    const data = window.Folio.formToHash(e.target)

    const methodName = data._method === 'patch' ? 'apiHtmlPatch' : 'apiHtmlPost'

    window.Folio.Api[methodName](e.target.action, { ...data, _ajax: '1' }, null, 'error').then((res) => {
      this.handleResponse(res)
      if (this.keepLoadingClass) {
        delete this.keepLoadingClass
      } else {
        this.element.classList.remove(this.loadingClass)
      }
    }).catch((err, a, b) => {
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
        } else if (json && json.data && json.data.redirected) {
          this.keepLoadingClass = true
          window.location.reload()
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

  updateTitle (str) {
    const titleElement = this.element.querySelector('.modal-title')

    if (str) {
      titleElement.innerText = str
      titleElement.classList.remove('invisible')
    } else {
      titleElement.classList.add('invisible')
    }
  }

  tryToGetTitleFromH1 () {
    const h1 = this.element.querySelector('h1')

    if (h1) {
      this.updateTitle(h1.innerText)
      h1.closest('.f-c-form-header').hidden = true
    } else {
      this.updateTitle()
    }
  }
})

window.Folio.Stimulus.register('f-c-form-modal-trigger', class extends window.Stimulus.Controller {
  static values = {
    url: String,
    title: { type: String, default: '' }
  }

  click (e) {
    e.preventDefault()
    window.FolioConsole.FormModal.open({ trigger: this.element, url: this.urlValue, title: this.titleValue })
  }
})
