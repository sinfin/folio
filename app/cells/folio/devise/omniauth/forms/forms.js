window.Folio.Stimulus.register('f-devise-omniauth-forms', class extends window.Stimulus.Controller {
  static targets = ['button']

  // Method called from parent controller to disable/enable buttons
  setDisabled(disabled) {
    this.buttonTargets.forEach(button => {
      button.disabled = disabled

      if (disabled) {
        button.classList.add('disabled')
      } else {
        button.classList.remove('disabled')
      }
    })
  }
})
