window.Folio.Stimulus.register('f-devise-omniauth-forms-trigger', class extends window.Stimulus.Controller {
  static values = { provider: String }

  click (e) {
    e.preventDefault()
    const btn = document.querySelector(`.f-devise-omniauth-forms__button[data-provider="${this.providerValue}"]`)

    if (btn) {
      btn.click()
    }
  }
})
