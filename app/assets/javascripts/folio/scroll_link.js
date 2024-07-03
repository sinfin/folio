window.Folio.Stimulus.register('f-scroll-link', class extends window.Stimulus.Controller {
  static values = { selector: String }

  click (e) {
    e.preventDefault()

    const target = document.querySelector(this.selectorValue)
    if (!target) return

    target.scrollIntoView({ behavior: 'smooth' })
  }
})
