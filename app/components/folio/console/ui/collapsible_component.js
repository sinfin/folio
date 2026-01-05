window.Folio.Stimulus.register('f-c-ui-collapsible', class extends window.Stimulus.Controller {
  static values = {
    collapsed: { type: Boolean, default: true }
  }

  onToggleClick (e) {
    e.preventDefault()
    this.collapsedValue = !this.collapsedValue

    if (!this.collapsedValue) {
      const input = this.element.querySelector('.f-c-ui-collapsible-focus-input')
      if (input) input.focus()
    }
  }
})
