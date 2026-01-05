window.Folio.Stimulus.register('f-c-ui-clipboard', class extends window.Stimulus.Controller {
  static classes = ['copied']

  connect () {
    this.clipboard = new window.ClipboardJS(this.element)

    this.clipboard.on('success', () => {
      this.element.classList.add(this.copiedClass)

      window.setTimeout(() => {
        if (!this.element.parentNode) return
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
