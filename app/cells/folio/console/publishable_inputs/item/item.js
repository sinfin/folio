window.Folio.Stimulus.register('f-c-publishable-inputs-item', class extends window.Stimulus.Controller {
  onCheckboxChange (e) {
    if (e.currentTarget.checked) {
      this.element.classList.add('f-c-publishable-inputs-item--active')

      const input = this.element.querySelector(window.Folio.Input.DateTime.SELECTOR)

      if (input && !input.value && input.folioInputTempusDominus) {
        const oneMinuteAgo = new Date() - 60 * 1000
        input.value = input.folioInputTempusDominus.dates.formatInput(new window.tempusDominus.DateTime(oneMinuteAgo))
      }
    } else {
      this.element.classList.remove('f-c-publishable-inputs-item--active')
    }
  }
})
