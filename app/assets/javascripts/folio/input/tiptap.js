window.Folio.Stimulus.register('f-input-tiptap', class extends window.Stimulus.Controller {
  static targets = ['input', 'iframe', 'loader']

  static values = {
    loaded: { type: Boolean, default: false },
    origin: String,
    type: String,
    renderUrl: String,
    tiptapNodesJson: String,
  }

  connect () {
    this.onWindowResize = window.Folio.debounce((e) => {
      this.setWindowWidth(e)
      this.sendWindowResizeMessage()
    })

    this.setWindowWidth()
    this.sendStartMessage()
  }

  setWindowWidth (e) {
    this.windowWidth = window.innerWidth
  }

  sendWindowResizeMessage () {
    const data = {
      type: 'f-input-tiptap:window-resize',
      windowWidth: this.windowWidth,
    }

    this.iframeTarget.contentWindow.postMessage(data, this.originValue || window.origin)
  }

  onWindowMessage (e) {
    if (this.originValue !== "*" && e.origin !== window.origin) return
    if (e.source !== this.iframeTarget.contentWindow) return
    if (!e.data) return

    switch (e.data.type) {
      case 'f-tiptap:created':
        this.setHeight(e.data.height)
        this.loadedValue = true
        break
      case 'f-tiptap:updated':
        this.setHeight(e.data.height)
        this.inputTarget.value = JSON.stringify(e.data.content)
        break
      case 'f-tiptap-node:render':
        this.onRenderNodeMessage(e)
        break
      case 'f-tiptap:javascript-evaluated':
        this.sendStartMessage()
        break
      case 'f-tiptap-editor:resized':
        this.setHeight(e.data.height)
        break
    }
  }

  setHeight (height) {
    if (typeof height !== 'number') return
    this.iframeTarget.style.height = `${height + 50}px`
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

    const data = {
      type: 'f-input-tiptap:start',
      content,
      folioTiptapNodes: this.tiptapNodesJsonValue ? JSON.parse(this.tiptapNodesJsonValue) : [],
      windowWidth: this.windowWidth,
    }

    if (this.originValue === "*") {
      const link = document.querySelector('link[rel="stylesheet"][href*="/assets/application."]')

      if (link && link.href) {
        data.stylesheetPath = link.href
      }
    }

    this.iframeTarget.contentWindow.postMessage(data, this.originValue || window.origin)
  }

  onRenderNodeMessage (e) {
    const data = {
      unique_id: e.data.uniqueId,
      attrs: e.data.attrs,
    }

    if (this.renderQueue) {
      this.renderQueue.push(data)
      return
    }

    this.renderQueue = [data]

    window.setTimeout(() => {
      if (!this.renderQueue) return

      const queue = this.renderQueue
      delete this.renderQueue

      this.renderNodesApi(queue)
    }, 50)
  }

  renderNodesApi (nodes) {
    window.Folio.Api.apiPost(this.renderUrlValue, { nodes }).then((res) => {
      if (res && res.data) {
        this.handleRenderNodesResponse(res.data)
        return
      }

      throw new Error('No data returned from API')
    }).catch((e) => {
      window.alert('Error: ' + e.message)
    })
  }

  handleRenderNodesResponse (nodes) {
    const data = {
      type: "f-input-tiptap:render-nodes",
      nodes,
    }

    this.iframeTarget.contentWindow.postMessage(data, this.originValue || window.origin)
  }
})
