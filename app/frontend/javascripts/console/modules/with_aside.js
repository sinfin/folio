window.Folio.Stimulus.register('f-c-with-aside', class extends window.Stimulus.Controller {
  toggle (e) {
    e.preventDefault()
    this.element.classList.toggle('f-c-with-aside--aside-collapsed')
  }
})
