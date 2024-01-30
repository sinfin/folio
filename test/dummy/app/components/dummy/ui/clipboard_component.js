//= require clipboard/dist/clipboard

window.Folio.Stimulus.register('d-ui-clipboard', class extends window.Stimulus.Controller {
  static classes = ["copied"]

  connect () {
    this.clipboard = new ClipboardJS(this.element)

    this.clipboard.on('success', () => {
      this.element.classList.add(this.copiedClass)

      window.setTimeout(() => {
        this.element.classList.remove(this.copiedClass)
      }, 1000)

    })
  }

  disconnect () {
    if (this.clipboard) {
      this.clipboard.destroy()
      delete this.clipboard
    }
  }
})
