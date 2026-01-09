window.Folio.Stimulus.register('f-c-tiptap-simple-form-wrap-locale-switch', class extends window.Stimulus.Controller {
  static targets = ['button']

  onAttributeClick (e) {
    const button = e.currentTarget
    const attributeName = button.dataset.attributeName

    // Update active state on buttons
    this.buttonTargets.forEach(btn => {
      btn.classList.toggle('f-c-tiptap-simple-form-wrap-locale-switch__btn--active', btn === button)
    })

    // Dispatch event to parent SimpleFormWrap component
    this.element.dispatchEvent(new CustomEvent('f-c-tiptap-simple-form-wrap-locale-switch:attributeChanged', {
      detail: {
        attributeName
      },
      bubbles: true
    }))
  }
})
