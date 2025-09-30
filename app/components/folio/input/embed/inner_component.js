window.Folio.Stimulus.register('f-input-embed-inner', class extends window.Stimulus.Controller {
  static values = {
    state: String
  }

  static targets = ['input', 'previewWrap', 'iframe']

  onInput (e) {
    this.updateStateBasedOnInputs()
  }

  stateValueChanged (to, from) {
    this.updatePreview()
  }

  updatePreview () {
    if (!this.iframeLoaded) {
      if (!this.hasIframeTarget) {
        this.previewWrapTarget.innerHTML = '<iframe class="f-input-embed-inner__iframe" src="/folio/embed"></iframe>'
      }
    }
  }

  onWindowMessage (e) {
    if (e.origin !== window.origin) return
    if (!e.data) return
    if (!this.hasIframeTarget) return
    if (e.source !== this.iframeTarget.contentWindow) return

    switch (e.data.type) {
      case 'f-embed:javascript-evaluated':
        this.iframeLoaded = true
        this.updatePreview()
        break
    }
  }
})
