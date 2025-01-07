window.Folio.Stimulus.register('f-c-links-control-bar', class extends window.Stimulus.Controller {
  static values = {
    href: String,
  }

  static outlets = ["f-c-links-modal"]

  onAddClick (e) {
    e.preventDefault()
    this.fCLinksModalOutlet.openWithData({ href: "/foo" })
  }
})
