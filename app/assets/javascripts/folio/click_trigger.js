window.Folio.Stimulus.register('f-click-trigger', class extends window.Stimulus.Controller {
  static values = { target: String }

  connect () {
    this.element.setAttribute('data-action', 'click->f-click-trigger#triggerClick')
  }

  triggerClick (e) {
    e.preventDefault()

    const target = document.querySelector(this.targetValue)

    if (target) target.click()
  }
})
