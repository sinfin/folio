window.Folio.Stimulus.register('f-c-danger-box-shadow-blink', class extends window.Stimulus.Controller {
  connect () {
    this.timeout = window.setTimeout(() => {
      this.element.classList.add('has-danger-blink')

      this.timeout = window.setTimeout(() => {
        this.element.classList.remove('has-danger-blink')
        delete this.element.dataset.controller
      }, 500)
    }, 0)
  }

  disconnect () {
    if (this.timeout) {
      window.clearTimeout(this.timeout)
      this.timeout = null
    }
  }
})
