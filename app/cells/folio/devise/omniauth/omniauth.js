// Controller for visible omniauth buttons
window.Folio.Stimulus.register('f-devise-omniauth', class extends window.Stimulus.Controller {
  // Method called from parent invitations controller
  setDisabled(disabled) {
    const buttons = this.element.querySelectorAll('.f-devise-omniauth__button')

    buttons.forEach(button => {
      button.disabled = disabled

      if (disabled) {
        button.classList.add('disabled')
      } else {
        button.classList.remove('disabled')
      }
    })
  }
})

// Shared trigger controller - used in multiple cells (omniauth, authentications...)
// Not a cell itself, but a utility controller
window.Folio.Stimulus.register('f-devise-omniauth-trigger', class extends window.Stimulus.Controller {
  static values = { provider: String }

  click (e) {
    e.preventDefault()

    if (e.currentTarget.disabled) {
      return
    }

    const btn = document.querySelector(`.f-devise-omniauth-forms__button[data-provider="${this.providerValue}"]`)

    if (btn && !btn.disabled) {
      btn.click()
    }
  }
})
