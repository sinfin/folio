window.Folio.Stimulus.register('f-c-links-control-bar', class extends window.Stimulus.Controller {
  static values = {
    href: String,
  }

  onAddClick (e) {
    e.preventDefault()
    console.log('onAddClick')
  }
})
