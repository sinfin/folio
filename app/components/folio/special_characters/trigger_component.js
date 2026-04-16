window.Folio.Stimulus.register('f-special-characters-trigger', class extends window.Stimulus.Controller {
  toggle () {
    const formFooter = this.element.closest('.f-c-form-footer')
    let target = this.element

    if (formFooter) {
      formFooter.dispatchEvent(new CustomEvent('f-c-form-footer:collapse'))
      // use document as target on mobile so that the popover is centered on the screen
      target = document
    }

    target.dispatchEvent(new CustomEvent('f-special-characters-trigger:toggle', { bubbles: true }))
  }

  preventDefault (e) {
    e.preventDefault()
  }
})
