window.Folio.Stimulus.register('f-c-layout-sidebar-title', class extends window.Stimulus.Controller {
  static classes = ['expanded']

  collapsibleToggle () {
    this.element.classList.toggle(this.expandedClass)
  }
})
