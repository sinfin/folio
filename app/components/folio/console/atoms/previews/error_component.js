window.Folio.Stimulus.register('f-c-atoms-previews-error', class extends window.Stimulus.Controller {
  static values = {
    timer: Number,
    error: String
  }

  static targets = ['timer', 'error']

  disconnect () {
    if (this.timeout) {
      window.clearTimeout(this.timeout)
      this.timeout = null
    }
  }

  errorValueChanged () {
    this.errorTarget.innerText = this.errorValue
  }

  timerValueChanged () {
    this.timerTarget.innerText = this.timerValue

    if (this.timerValue > 0) {
      this.timeout = window.setTimeout(() => {
        this.timerValue = Math.max(0, this.timerValue - 1)
      }, 1000)
    } else {
      window.top.postMessage({ type: 'refreshPreview' }, window.origin)
    }
  }
})
