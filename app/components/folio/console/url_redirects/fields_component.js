window.Folio.Stimulus.register('f-c-url-redirects-fields', class extends window.Stimulus.Controller {
  static targets = ['demo', 'demoCases', 'demoUnpublished', 'demoInvalid', 'demoLoader']

  static values = {
    demoLoading: Boolean,
    demoApiUrl: String,
  }

  inputBlurred (e) {
    const input = e.target

    if (!input.value) return

    let url

    try {
      const urlObject = new URL(input.value)
      url = urlObject.pathname
      if (urlObject.search) url += urlObject.search
    } catch {
      url = input.value.indexOf('/') === 0 ? input.value : `/${input.value}`
    }

    input.value = url
  }

  inputChanged () {
    this.updateDemo()
  }

  updateDemo () {
    this.demoLoadingValue = true
    console.log('updateDemo!')
  }
})
