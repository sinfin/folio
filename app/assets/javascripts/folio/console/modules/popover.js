window.Folio.Stimulus.register('f-c-popover', class extends window.Stimulus.Controller {
  static values = {
    content: String,
    placement: { type: String, default: 'auto' },
    trigger: { type: String, default: 'hover' }
  }

  connect () {
    console.log(this.placementValue)

    this.element.dataset.bsPlacement = this.placementValue

    this.popover = new window.bootstrap.Popover(this.element, {
      content: this.contentValue,
      html: true,
      trigger: this.triggerValue,
      placement: this.placementValue,
      delay: {
        show: 0,
        hide: 100
      }
    })
  }

  disconnect () {
    this.popover.dispose()
    delete this.popover
  }
})
