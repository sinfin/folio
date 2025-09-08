window.Folio.Stimulus.register('f-c-ui-collapsible', class extends window.Stimulus.Controller {
  static values = {
    collapsed: { type: Boolean, default: true }
  }

  onToggleClick (e) {
    e.preventDefault()
    this.collapsedValue = !this.collapsedValue
  }
})
