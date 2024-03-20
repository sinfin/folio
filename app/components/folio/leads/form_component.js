window.Folio.Stimulus.register('f-leads-form', class extends window.Stimulus.Controller {
  static targets = ['form']

  static values = {
    loading: Boolean,
    failureMessage: String,
  }

  submit () {
    if (this.loadingValue) return

    this.loadingValue = true

    const data = window.Folio.formToHash(this.formTarget)
    const url = this.formTarget.action

    window.Folio.Api.apiPost(url, data).then((res) => {
      if (res && res.data) {
        this.element.outerHTML = res.data
        this.loadingValue = false
      } else {
        throw new Error('No data')
      }
    }).catch((err) => {
      window.alert(this.failureMessageValue)
      this.loadingValue = false
    })
  }

  onFormSubmit (e) {
    e.preventDefault()
    this.submit()
  }
})
