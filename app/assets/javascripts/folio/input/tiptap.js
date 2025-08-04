window.Folio.Stimulus.register('f-input-tiptap', class extends window.Stimulus.Controller {
  static targets = ['input', 'iframe', 'loader']

  static values = {
    loaded: { type: Boolean, default: false },
    origin: String,
    type: String,
    renderUrl: String,
    tiptapConfigJson: String,
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
      case 'f-tiptap-editor:open-link-popover':
        this.openLinkPopover(e.data.urlJson)
        break
      case 'f-tiptap-editor:show-html':
        this.showHtmlInModal(e.data.html)
        break
    }
  }

  setHeight (height) {
    if (typeof height !== 'number') return
    this.iframeTarget.style.height = `${height + 2}px`
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
      lang: document.documentElement.lang || 'en',
      folioTiptapConfig: this.tiptapConfigJsonValue ? JSON.parse(this.tiptapConfigJsonValue) : {},
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

    if (!data.unique_id) return

    if (this.renderQueue) {
      // remove any existing render request for this unique_id
      this.renderQueue = this.renderQueue.filter(item => item.unique_id !== data.unique_id)
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

  openLinkPopover (urlJson) {
    const detail = {
      urlJson,
      trigger: this,
      json: true,
      disableLabel: true,
    }

    document.querySelector('.f-c-links-modal').dispatchEvent(new window.CustomEvent('f-c-links-modal:open', { detail }))
  }

  saveUrlJson (urlJson) {
    const data = {
      type: 'f-input-tiptap:save-url-json',
      urlJson,
    }

    this.iframeTarget.contentWindow.postMessage(data, this.originValue || window.origin)
  }

  showHtmlInModal (html) {
    if (!html) return

    const modal = document.querySelector('.f-c-tiptap-html-modal')

    if (modal) {
      const code = modal.querySelector('.f-c-tiptap-html-modal__code')

      if (code) {
        code.textContent = html
        window.Folio.Modal.open(modal)
        return
      }
    }

    console.group('[Folio] [Tiptap] HTML')
    console.log(html)
    console.groupEnd()

    window.alert("HTML output logged to console.")
  }
})
