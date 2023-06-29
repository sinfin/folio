window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.Reports = window.FolioConsole.Reports || {}
window.FolioConsole.Report = {}

window.FolioConsole.Report.i18n = {
  cs: {
    loadFailure: 'Nepodařilo se načíst data. Zkuste to prosím později.'
  },
  en: {
    loadFailure: 'Failed to load data. Please try again later.'
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

    window.Folio.Api.apiHtmlGet(`${url}&_ajax=1`, null, this.abortController.signal)
      .then((res) => {
        this.handleLoadSuccess(res)
        window.history.pushState(null, '', url)
      })
      .catch((error) => this.handleLoadError(error))
  }

  handleLoadSuccess (res) {
    const parser = new window.DOMParser()
    const doc = parser.parseFromString(res, 'text/html')
    const index = doc.querySelector('.f-c-report')

    if (index) {
      const oldDateValue = this.dateInputTarget.value
      const oldDateParam = this.dateInputTarget.dataset.paramValue
      const oldGroupByValue = this.groupByInputTarget.value
      const oldGroupByParam = this.groupByInputTarget.dataset.paramValue

      this.element.replaceWith(index)

      const newGroupByInput = index.querySelector('.f-c-report__header-group-by-input')
      if (oldGroupByValue !== newGroupByInput.value || (oldGroupByParam && oldGroupByParam !== newGroupByInput.value)) {
        const groupByWrap = newGroupByInput.closest('.f-c-report__header-group-by-wrap')
        if (groupByWrap) groupByWrap.dataset.controller = 'f-c-danger-box-shadow-blink'
      }

      const newDateInput = index.querySelector('.f-c-report__header-date-input')
      if (oldDateValue !== newDateInput.value || (oldDateParam && oldDateParam !== newDateInput.value)) {
        const dateWrap = newDateInput.closest('.f-c-report__header-date-wrap')
        if (dateWrap) dateWrap.dataset.controller = 'f-c-danger-box-shadow-blink'
      }
    } else {
      this.handleLoadError(new Error(window.Folio.i18n(window.FolioConsole.Report.i18n, 'loadFailure')))
    }
  }

  handleLoadError (error) {
    if (error.name === 'AbortError') return

    this.contentTarget.innerHTML = ''

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
