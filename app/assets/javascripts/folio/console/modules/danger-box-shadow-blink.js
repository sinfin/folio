window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.DangerBoxShadowBlink = window.FolioConsole.DangerBoxShadowBlink || {}

window.FolioConsole.DangerBoxShadowBlink.blinkFormGroup = (formGroup) => {
  if (!formGroup) return

  if (formGroup.dataset.controller) {
    if (formGroup.dataset.controller.indexOf('f-c-danger-box-shadow-blink') === -1) {
      formGroup.dataset.controller += ' f-c-danger-box-shadow-blink'
    }
  } else {
    formGroup.dataset.controller = 'f-c-danger-box-shadow-blink'
  }
}

window.Folio.Stimulus.register('f-c-danger-box-shadow-blink', class extends window.Stimulus.Controller {
  connect () {
    this.timeout = window.setTimeout(() => {
      this.element.classList.add('has-danger-blink')

      const input = this.element.querySelector('.form-control.is-invalid')

      if (input) {
        input.focus()
      }

      this.timeout = window.setTimeout(() => {
        this.element.classList.remove('has-danger-blink')
        const newController = this.element.dataset.controller.replace('f-c-danger-box-shadow-blink', '').trim()

        if (newController) {
          this.element.dataset.controller = newController
        } else {
          delete this.element.dataset.controller
        }
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
