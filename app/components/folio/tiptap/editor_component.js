//= require folio/stimulus

window.Folio.Stimulus.register('f-tiptap-editor', class extends window.Stimulus.Controller {
  static targets = ['reactRoot']

  static values = {
    type: String,
  }

  connect () {
    if (this.reactRoot) return

    if (!this.hasReactRootTarget) {
      this.element.insertAdjacentHTML('beforeend', '<div class="f-tiptap-editor__react-root" data-f-tiptap-editor-target="reactRoot"></div>')
    }

    this.boundOnUpdate = this.onUpdate.bind(this)

    window.Folio.RemoteScripts.run('folio-tiptap', () => {
      let content = null

      if (this.inputTarget.value) {
        try {
          content = JSON.parse(this.inputTarget.value)
        } catch (e) {
          console.error('Failed to parse input value as JSON:', e)
        }
      }

      this.reactRoot = window.Folio.Tiptap.init({
        node: this.reactRootTarget,
        onUpdate: this.boundOnUpdate,
        content,
      })
    }, () => {
      console.error('Failed to load folio-tiptap!')
    })
  }

  disconnect () {
    if (this.reactRoot) {
      window.Folio.Tiptap.destroy(this.reactRoot)
      delete this.reactRoot
    }

    if (this.boundOnUpdate) {
      delete this.boundOnUpdate
    }
  }

  onUpdate ({ editor }) {
    console.log('Tiptap editor updated:', editor.getJSON())
    // this.inputTarget.value = JSON.stringify(editor.getJSON())
  }
})
