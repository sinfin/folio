window.Folio.Stimulus.register('f-input-tiptap', class extends window.Stimulus.Controller {
  static targets = ['input', 'iframe', 'loader']

  static values = {
    loading: { type: Boolean, default: true },
    origin: String,
  }

  connect () {
    this.sendStartMessage()
  }

  onWindowMessage (e) {
    if (this.originValue !== "*" && e.origin !== window.origin) return
    if (e.source !== this.iframeTarget.contentWindow) return
    if (!e.data) return
    if (e.data.type.indexOf('f-tiptap:') !== 0) return

    if (e.data.type === 'f-tiptap:javascript-evaluated') {
      this.sendStartMessage()
    } else {
      this.setHeight(e.data.height)

      if (e.data.type === 'f-tiptap:created') {
        this.loadingValue = false
      } else if (e.data.type === 'f-tiptap:updated') {
        this.setHeight(e.data.height)
        this.inputTarget.value = JSON.stringify(e.data.content)
      }
    }
  }

  setHeight (height) {
    if (typeof height !== 'number') return
    this.iframeTarget.style.minHeight = `${height}px`
  }

  sendStartMessage () {
    let content = null

    if (this.inputTarget.value) {
      try {
        content = JSON.parse(this.inputTarget.value)
      } catch (e) {
        console.error('Failed to parse input value as JSON:', e)
      }
    }

    this.iframeTarget.contentWindow.postMessage({
      type: 'f-input-tiptap:start',
      content,
    }, this.originValue || window.origin)
  }
})
