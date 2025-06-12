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
  static targets = ['input', 'reactRoot']

  connect () {
    if (this.reactRoot) return

    if (!this.hasReactRootTarget) {
      this.element.insertAdjacentHTML('beforeend', '<div class="f-input-tiptap__react-root" data-f-input-tiptap-target="reactRoot"></div>')
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
    this.inputTarget.value = JSON.stringify(editor.getJSON())
  }
})
