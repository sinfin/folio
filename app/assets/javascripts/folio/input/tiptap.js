//= require autosize/dist/autosize

window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.Tiptap = {}

window.Folio.Input.Tiptap.bind = (input) => {
  console.log('tiptap bind', input)
}

window.Folio.Input.Tiptap.unbind = (input) => {
  console.log('tiptap unbind', input)
}

window.Folio.Stimulus.register('f-input-tiptap', class extends window.Stimulus.Controller {
  static targets = ['input', 'iframe']

  connect () {
    if (!this.hasIframeTarget) {
      this.element.insertAdjacentHTML('beforeend', '<iframe class="f-input-tiptap__iframe" data-f-input-tiptap-target="iframe" src="/folio-tiptap/block_editor"></iframe>')
    }
  }

  disconnect () {
  }

  onWindowMessage (e) {
    if (!e.data) return
    if (e.data.type.indexOf('f-tiptap-editor:') !== 0) return

    this.setHeight(e.data.height)

    if (e.data.type === 'f-tiptap-editor:updated') {
      this.setHeight(e.data.height)
      this.inputTarget.value = JSON.stringify(e.data.content)
    }
  }

  setHeight (height) {
    if (typeof height !== 'number') return
    this.iframeTarget.style.minHeight = `${height}px`
  }
})
