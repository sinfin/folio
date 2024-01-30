//= require clipboard/dist/clipboard

window.Folio.Stimulus.register('d-ui-clipboard', class extends window.Stimulus.Controller {
  static values = {
    clipboard: Object
  }

  connect () {
    this.bindClipboardsIn(document.body)
    this.onClipboardsIn.bind(this)
  }

  disconnect () {
    this.unbindClipboardsIn(document.body)
  }

  bindClipboardsIn (wrap) {
    this.unbindClipboardsIn(wrap)

    const clipboardElements = wrap.querySelectorAll('.d-ui-clipboard')

    clipboardElements.forEach((element) => {
      const clipboard = new ClipboardJS(element)
      clipboard.on('success', this.onClipboardsIn)
      element.clipboardValue = clipboard
    })
  }

  unbindClipboardsIn (wrap) {
    const clipboardElements = wrap.querySelectorAll('.d-ui-clipboard')

    clipboardElements.forEach((element) => {
      const clipboard = element.clipboardValue

      if (clipboard) {
        clipboard.destroy()
      }

      element.clipboardValue = null

      if (this.boundOnClipboardsIn) {
        delete this.boundOnClipboardsIn
      }
    })
  }

  onClipboardsIn (e) {
    const trigger = e.trigger
    trigger.classList.add('d-ui-clipboard--copied')
    setTimeout(() => trigger.classList.remove('d-ui-clipboard--copied'), 1000)
  }
})
