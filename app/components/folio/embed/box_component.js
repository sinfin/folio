//= require folio/intersection-observer

window.Folio = window.Folio || {}
window.Folio.Embed = window.Folio.Embed || {}
window.Folio.Embed.Box = window.Folio.Embed.Box || {}

window.Folio.Embed.Box.intersectionObserver = window.Folio.intersectionObserver({
  callback: (entry) => {
    entry.target.dataset.fEmbedBoxIntersectedValue = true
  }
})

window.Folio.Stimulus.register('f-embed-box', class extends window.Stimulus.Controller {
  static values = {
    intersected: Boolean,
    folioEmbedData: Object
  }

  static targets = ['iframe', 'loader']

  connect () {
    this.bindIntersectionObserver()
  }

  disconnect () {
    this.unbindIntersectionObserver()
  }

  bindIntersectionObserver () {
    window.Folio.Embed.Box.intersectionObserver.observe(this.element)
  }

  unbindIntersectionObserver () {
    window.Folio.Embed.Box.intersectionObserver.unobserve(this.element)
  }

  load () {
    if (!this.intersectedValue) return
    if (!this.folioEmbedDataValue) return

    this.iframeTargets.forEach((iframeTarget) => {
      iframeTarget.remove()
    })

    this.element.insertAdjacentHTML('afterbegin', '<iframe class="f-embed-box__iframe" src="/folio/embed" data-f-embed-box-target="iframe"></iframe>')
  }

  intersectedValueChanged (newValue, _oldValue) {
    this.load()
  }

  folioEmbedDataValueChanged (newValue, _oldValue) {
    console.log('folioEmbedDataV...ged', 'newValue:', newValue, '_oldValue:', _oldValue)
    this.load()
  }

  onWindowMessage (e) {
    if (e.origin !== window.origin) return
    if (!e.data) return
    if (!this.intersectedValue) return
    if (!this.folioEmbedDataValue) return
    if (!this.hasIframeTarget) return
    if (e.source !== this.iframeTarget.contentWindow) return

    switch (e.data.type) {
      case 'f-embed:javascript-evaluated':
        this.sendFolioEmbedDataToIframe()
        break
      case 'f-embed:rendered-embed':
        this.loaderTarget.hidden = true
        break
      case 'f-embed:resized':
        this.handleEmbedResized(e.data)
        break
    }
  }

  handleEmbedResized (data) {
    this.iframeTarget.style.height = `${data.height}px`
  }

  sendFolioEmbedDataToIframe () {
    this.iframeTarget.contentWindow.postMessage({
      type: 'f-embed:set-data',
      folioEmbedData: this.folioEmbedDataValue
    }, window.origin)
  }

  onInnerUpdate (e) {
    console.log('onInnerUpdate', e.detail.folioEmbedData)
    this.folioEmbedDataValue = e.detail.folioEmbedData
  }
})
