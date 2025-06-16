window.Folio.Stimulus.register('f-tiptap-editor', class extends window.Stimulus.Controller {
  static targets = ['reactRoot', 'loader']

  static values = {
    type: String,
    tiptapContent: String,
  }

  connect () {
    if (this.reactRoot) return

    if (!this.hasReactRootTarget) {
      this.element.insertAdjacentHTML('beforeend', '<div class="f-tiptap-editor__react-root" data-f-tiptap-editor-target="reactRoot"></div>')
    }

    this.boundOnCreate = this.onCreate.bind(this)
    this.boundOnUpdate = this.onUpdate.bind(this)

    document.documentElement.classList.add('f-tiptap-editor-html')
    document.body.classList.add('f-tiptap-editor-body')

    window.Folio.RemoteScripts.run('folio-tiptap', () => {
      let content = null

      if (this.tiptapContentValue) {
        try {
          content = JSON.parse(this.tiptapContentValue)
        } catch (e) {
          console.error('Failed to parse input value as JSON:', e)
        }
      }

      this.reactRoot = window.Folio.Tiptap.init({
        node: this.reactRootTarget,
        onCreate: this.boundOnCreate,
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

  onCreate () {
    window.top.postMessage({
      type: 'f-tiptap-editor:created',
      height: this.element.clientHeight,
    }, window.origin)

    this.loaderTarget.remove()
  }

  onUpdate ({ editor }) {
    window.top.postMessage({
      type: 'f-tiptap-editor:updated',
      content: editor.getJSON(),
      height: this.element.clientHeight,
    }, window.origin)
  }
})
