window.Folio.Stimulus.register('f-c-files-show-thumbnails-main', class extends window.Stimulus.Controller {
  static targets = ['toggle']

  static values = {
    detailsId: String,
    expanded: Boolean
  }

  toggleDetails (event) {
    event.preventDefault()
    this.expandedValue = !this.expandedValue
  }

  expandedValueChanged () {
    const details = this.detailsElement()
    if (details) details.hidden = !this.expandedValue

    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute('aria-expanded', this.expandedValue)
    }
  }

  detailsElement () {
    return this.element.closest('.f-c-files-show')?.querySelector(`#${this.detailsIdValue}`)
  }
})
