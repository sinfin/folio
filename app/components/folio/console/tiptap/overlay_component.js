window.Folio.Stimulus.register('f-c-tiptap-overlay', class extends window.Stimulus.Controller {
  static values = {
    state: String,
    origin: String,
    editUrl: String,
    saveUrl: String
  }

  static targets = ['formWrap']

  disconnect () {
    delete this.iframeWindowReference
    delete this.nodeUniqueId
    delete this.editorContext
    this.abortAjax()
  }

  abortAjax () {
    if (!this.abortController) return

    this.abortController.abort()
    delete this.abortController
  }

  backdropClick () {
    this.close()
  }

  close () {
    this.stateValue = 'closed'
  }

  onWindowMessage (e) {
    if (this.originValue !== '*' && e.origin !== window.origin) return
    if (!e.data) return

    if (e.data.type === 'f-tiptap-slash-command:selected') {
      this.onSlashCommandSelectedMessage(e)
    } else if (e.data.type === 'f-tiptap-node:click') {
      this.onNodeClickMessage(e)
    }
  }

  onSlashCommandSelectedMessage (e) {
    this.onNodeClickMessage(e)
  }

  onNodeClickMessage (e) {
    this.iframeWindowReference = e.source
    this.nodeUniqueId = e.data.uniqueId || null
    this.editorContext = this.editorContextForSource(e.source)
    this.stateValue = 'loading'

    this.ajax({
      url: this.editUrlValue,
      data: this.withEditorContext({ tiptap_node_attrs: e.data.attrs })
    })
  }

  editorContextForSource (source) {
    const input = Array.from(document.querySelectorAll('.f-input-tiptap')).find((element) => {
      const iframe = element.querySelector('.f-input-tiptap__iframe')
      return iframe && iframe.contentWindow === source
    })

    if (!input) throw new Error('No source Tiptap input found')

    const context = {
      placement_type: input.dataset.fInputTiptapPlacementTypeValue,
      placement_id: input.dataset.fInputTiptapPlacementIdValue,
      attribute_name: input.dataset.fInputTiptapAttributeNameValue
    }

    const opaqueContext = input.dataset.fInputTiptapEditorContextJsonValue
    if (opaqueContext) context.context = JSON.parse(opaqueContext)

    return context
  }

  withEditorContext (data) {
    return Object.assign({}, data, { tiptap_editor_context: this.editorContext })
  }

  ajax ({ url, data, apiMethod = 'apiPost' }) {
    this.abortAjax()
    this.abortController = new AbortController()

    window.Folio.Api[apiMethod](url, data, this.abortController.signal).then((res) => {
      if (res) {
        if (res.meta && res.meta.tiptap_node_valid && res.data.tiptap_node) {
          this.handleValidNode(res.data.tiptap_node)
          this.stateValue = 'closed'
          return
        } else if (res.data) {
          this.formWrapTarget.innerHTML = res.data
          this.stateValue = 'loaded'
          return
        }
      }

      throw new Error('No data returned from API')
    }).catch((e) => {
      this.stateValue = 'closed'
      window.alert('Error: ' + e.message)
    }).finally(() => {
      delete this.abortController
    })
  }

  onFormSubmit (e) {
    this.ajax({
      url: this.saveUrlValue,
      data: this.withEditorContext(e.detail.data)
    })
  }

  handleValidNode (nodeHash) {
    if (!this.iframeWindowReference) {
      throw new Error('No iframe window reference found')
    }

    this.iframeWindowReference.postMessage({
      type: 'f-c-tiptap-overlay:saved',
      node: nodeHash,
      uniqueId: this.nodeUniqueId
    }, this.originValue || window.origin)
  }
})
