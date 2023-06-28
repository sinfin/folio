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

window.Folio.Stimulus.register('f-c-report', class extends window.Stimulus.Controller {
  static targets = ['form', 'dateInput', 'groupByInput', 'content']

  static values = {
    loading: Boolean
  }

  connect () {
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

    const originalParams = new URLSearchParams(window.location.search)
    const changedDate = originalParams.get(this.dateInputTarget.name) !== this.dateInputTarget.value
    const changedGroupBy = originalParams.get(this.groupByInputTarget.name) !== this.groupByInputTarget.value

    window.Folio.Api.apiHtmlGet(`${url}&_ajax=1`, null, this.abortController.signal)
      .then((res) => {
        window.history.pushState(null, "", url)
        this.handleLoadSuccess({ res, changedDate, changedGroupBy })
      })
      .catch((error) => this.handleLoadError(error))
  }

  handleLoadSuccess ({ res, changedDate, changedGroupBy }) {
    const parser = new window.DOMParser()
    const doc = parser.parseFromString(res, 'text/html')
    const index = doc.querySelector('.f-c-report')

    if (index) {
      this.element.replaceWith(index)

      if (changedGroupBy) {
        const groupByWrap = index.querySelector('.f-c-report__header-group-by-wrap')
        if (groupByWrap) groupByWrap.dataset.controller = "f-c-danger-box-shadow-blink"
      }

      if (changedDate) {
        const dateWrap = index.querySelector('.f-c-report__header-date-wrap')
        if (dateWrap) dateWrap.dataset.controller = "f-c-danger-box-shadow-blink"
      }
    } else {
      this.handleLoadError(new Error(window.Folio.i18n(window.FolioConsole.Reports.Index.i18n, 'loadFailure')))
    }
  }

  handleLoadError (error) {
    if (error.name === "AbortError") return

    this.contentTarget.innerHTML = ""

    const errorDiv = document.createElement('p')

    errorDiv.classList.add('f-c-report__error')
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
