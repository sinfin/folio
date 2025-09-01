window.Folio.Stimulus.register('f-input-tiptap', class extends window.Stimulus.Controller {
  static targets = ['input', 'iframe', 'loader']

  static AUTO_SAVE_DELAY = 2000

  static values = {
    loaded: { type: Boolean, default: false },
    readonly: { type: Boolean, default: false },
    ignoreValueChanges: { type: Boolean, default: true },
    origin: String,
    type: String,
    renderUrl: String,
    autoSaveUrl: String,
    tiptapConfigJson: String,
    tiptapContentJsonStructureJson: String,
    autoSave: { type: Boolean, default: false },
    placementType: String,
    placementId: Number,
    latestRevisionCreatedAt: String,
  }

  connect () {
    this.onWindowResize = window.Folio.debounce((e) => {
      this.setWindowWidth(e)
      this.sendWindowResizeMessage()
    })

    this.debouncedAutoSave = window.Folio.debounce(() => {
      this.performAutoSave()
    }, this.constructor.AUTO_SAVE_DELAY)

    this.restoreScrollPositions()
    this.setWindowWidth()
    this.sendStartMessage()
  }

  disconnect () {
    this.storeScrollPositions()
  }

  onWindowBeforeUnload () {
    this.storeScrollPositions()
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
        this.setInputValue(e.data.content)
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
      case 'f-tiptap-editor:scrolled':
        this.tiptapScrollTop = e.data.scrollTop
        break
      case 'f-tiptap-editor:open-link-popover':
        this.openLinkPopover(e.data.urlJson)
        break
      case 'f-tiptap-editor:initialized-content':
        this.setInputValue(e.data.content, { isInitialization: true })
        this.ignoreValueChangesValue = false

        this.sendSaveButtonInfo()
        break
      case 'f-tiptap-editor:show-html':
        this.showHtmlInModal(e.data.html)
        break
    }
  }

  setInputValue (content, options = {}) {
    const textsArray = []

    if (content) {
      const recursivelyExtractTexts = (node) => {
        if (node.type === 'text' && node.text) {
          textsArray.push(node.text)
        } else if (Array.isArray(node.content)) {
          node.content.forEach(recursivelyExtractTexts)
        }
      }

      recursivelyExtractTexts(content)
    }

    const text = textsArray.join('\n')
    const wordCount = window.Folio.wordCount({ text })
    const valueKeys = this.valueKeys()

    if (content) {
      const value = {
        [valueKeys['content']]: content,
        [valueKeys['text']]: text,
        [valueKeys['word_count']]: wordCount.words,
        [valueKeys['character_count']]: wordCount.characters,
      }

      this.inputTarget.value = JSON.stringify(value)
    } else {
      this.inputTarget.value = ''
    }

    if (!this.ignoreValueChangesValue) {
      this.inputTarget.dispatchEvent(new window.Event("change", { bubbles: true }))
      this.dispatch("updateWordCount", { detail: { wordCount } })

      if (this.autoSaveValue && content && !options.isInitialization) {
        this.latestContent = content
        this.debouncedAutoSave()
      }
    }
  }

  setHeight (height) {
    if (typeof height !== 'number') return
    this.iframeTarget.style.height = `${height + 2}px`
  }

  valueKeys () {
    this.parsedValueKeys = this.parsedValueKeys || JSON.parse(this.tiptapContentJsonStructureJsonValue)
    return this.parsedValueKeys
  }

  sendStartMessage () {
    let value = null

    if (this.inputTarget.value) {
      try {
        value = JSON.parse(this.inputTarget.value)
      } catch (e) {
        console.error('Failed to parse input value as JSON:', e)
      }
    }

    const valueKeys = this.valueKeys()

    if (value && typeof value[valueKeys['word_count']] === 'number' && typeof value[valueKeys['character_count']] === 'number') {
      const wordCount = window.Folio.wordCount({
        words: value[valueKeys['word_count']],
        characters: value[valueKeys['character_count']]
      })
      this.dispatch("updateWordCount", { detail: { wordCount } })
    }

    const data = {
      type: 'f-input-tiptap:start',
      content: value ? value[valueKeys['content']] : null,
      lang: document.documentElement.lang || 'en',
      folioTiptapConfig: this.tiptapConfigJsonValue ? JSON.parse(this.tiptapConfigJsonValue) : {},
      windowWidth: this.windowWidth,
      tiptapScrollTop: this.tiptapScrollTop || 0,
      readonly: this.readonlyValue,
    }

    if (this.originValue === "*") {
      const link = document.querySelector('link[rel="stylesheet"][href*="/assets/application."]')

      if (link && link.href) {
        data.stylesheetPath = link.href
      }
    }

    this.iframeTarget.contentWindow.postMessage(data, this.originValue || window.origin)
  }

  sendSaveButtonInfo () {
    const data = {
      type: 'f-input-tiptap:save-button-info',
      autoSaveEnabled: this.autoSaveValue,
      latestRevisionCreatedAt: this.latestRevisionCreatedAtValue || null,
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

  storeScrollPositions () {
    if (this.typeValue !== "block") return
    if (!this.tiptapScrollTop) return

    const scroll = {
      mainScroll: this.element.closest('.f-c-tiptap-simple-form-wrap__scroller').scrollTop,
      mainHeight: this.element.closest('.f-c-tiptap-simple-form-wrap__scroller').clientHeight,
      iframe: this.tiptapScrollTop,
    }

    window.sessionStorage.setItem('f-input-tiptap-scroll',
                                  JSON.stringify({ at: Date.now(), scroll }))
  }

  restoreScrollPositions () {
    if (this.typeValue !== "block") return

    const stored = window.sessionStorage.getItem('f-input-tiptap-scroll')

    if (!stored) return

    try {
      const storedData = JSON.parse(stored)
      const now = Date.now()

      if (now - storedData.at < 20000) { // 20 seconds
        this.tiptapScrollTop = storedData.scroll.iframe

        if (storedData.scroll.mainScroll) {
          const scroller = this.element.closest('.f-c-tiptap-simple-form-wrap__scroller')
          if (scroller) {
            const heightDiff = scroller.scrollHeight - storedData.scroll.mainHeight
            const scrollTop = Math.max(0, storedData.scroll.mainScroll + heightDiff)
            scroller.scrollTop = scrollTop
          }
        }
      }

      window.sessionStorage.removeItem('f-input-tiptap-scroll')
    } catch (e) {
      console.error('Failed to restore scroll positions:', e)
    }
  }

  performAutoSave () {
    if (!this.autoSaveValue || !this.autoSaveUrlValue || !this.placementTypeValue || !this.placementIdValue) return
    if (!this.latestContent) return

    const data = {
      tiptap_revision: {
        content: this.latestContent
      },
      placement: {
        type: this.placementTypeValue,
        id: this.placementIdValue
      }
    }

    window.Folio.Api.apiPost(this.autoSaveUrlValue, data)
      .then((response) => {
        if (response && response.success) {
          console.log('[Folio] [Tiptap] Auto-saved revision:', response.revision_number)

          const autoSaveMessage = {
            type: 'f-input-tiptap:auto-saved',
            revisionId: response.revision_id,
            revisionNumber: response.revision_number,
            createdAt: response.created_at
          }
          this.iframeTarget.contentWindow.postMessage(autoSaveMessage, this.originValue || window.origin)
        }
      })
      .catch((error) => {
        console.warn('[Folio] [Tiptap] Auto-save failed:', error)
      })
  }
})
