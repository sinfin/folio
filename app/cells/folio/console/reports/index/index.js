window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.Reports = window.FolioConsole.Reports || {}
window.FolioConsole.Reports.Index = {}

window.FolioConsole.Reports.Index.i18n = {
  cs: {
    loadFailure: "Nepodařilo se načíst data. Zkuste to prosím později.",
  },
  en: {
    loadFailure: "Failed to load data. Please try again later.",
  }
}

window.Folio.Stimulus.register('f-c-reports-index', class extends window.Stimulus.Controller {
  static targets = ['form', 'dateInput', 'groupByInput', 'content']

  static values = {
    loading: Boolean
  }

  connect () {
    console.log('connect')
    if (this.loadingValue) this.load()
  }

  disconnect () {
    if (this.abortController) {
      this.abortController.abort()
      this.abortController = null
    }
  }

  load () {
    this.loadingValue = true

    if (this.abortController) {
      this.abortController.abort()
    }

    this.abortController = new AbortController()

    const params = new URLSearchParams()
    params.set(this.dateInputTarget.name, this.dateInputTarget.value)
    params.set(this.groupByInputTarget.name, this.groupByInputTarget.value)

    const urlBase = this.formTarget.action
    const joiner = urlBase.indexOf('?') === -1 ? '?' : '&'
    const url = `${urlBase}${joiner}${params.toString()}`


    window.Folio.Api.apiHtmlGet(`${url}&_ajax=1`, null, this.abortController.signal)
      .then((res) => {
        window.history.pushState(null, "", url)
        this.handleLoadSuccess(res)
      })
      .catch((error) => this.handleLoadError(error))
  }

  handleLoadSuccess (res) {
    const parser = new window.DOMParser()
    const doc = parser.parseFromString(res, 'text/html')
    const index = doc.querySelector('.f-c-reports-index')

    if (index) {
      this.element.replaceWith(index)
    } else {
      this.handleLoadError(new Error(window.Folio.i18n(window.FolioConsole.Reports.Index.i18n, 'loadFailure')))
    }
  }

  handleLoadError (error) {
    if (error.name === "AbortError") return

    this.contentTarget.innerHTML = ""

    const errorDiv = document.createElement('p')

    errorDiv.classList.add('f-c-reports-index__error')
    errorDiv.innerText = error.message

    this.contentTarget.appendChild(errorDiv)

    this.loadingValue = false
  }

  onFormChange (e) {
    e.preventDefault()
    this.load()
  }

  onFormSubmit (e) {
    e.preventDefault()
    this.load()
  }
})
