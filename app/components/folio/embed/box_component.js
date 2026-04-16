//= require folio/intersection-observer
//= require folio/embed/relative_luminance

window.Folio = window.Folio || {}
window.Folio.Embed = window.Folio.Embed || {}
window.Folio.Embed.Box = window.Folio.Embed.Box || {}

window.Folio.Embed.Box.intersectionObserver = window.Folio.intersectionObserver({
  callback: (entry) => {
    entry.target.dataset.fEmbedBoxIntersectedValue = true
  }
})

window.Folio.Embed.Box.load = (element) => {
  if (element && element.classList.contains('f-embed-box')) {
    if (element.dataset.fEmbedBoxIntersectedValue === 'false') {
      element.dispatchEvent(new CustomEvent('f-embed-box:load', { bubbles: true }))
    }
  }
}

window.Folio.Stimulus.register('f-embed-box', class extends window.Stimulus.Controller {
  static values = {
    intersected: Boolean,
    folioEmbedData: Object,
    centered: Boolean,
    backgroundColor: String,
    lightModeBackgroundColor: String,
    darkModeBackgroundColor: String
  }

  static targets = ['iframe', 'loader']

  static isHexColor (value) {
    return typeof value === 'string' && /^#[0-9A-Fa-f]{6}$/.test(value)
  }

  connect () {
    this.bindIntersectionObserver()
  }

  disconnect () {
    this.unbindIntersectionObserver()
  }

  get hasDualBackgroundColors () {
    return this.constructor.isHexColor(this.lightModeBackgroundColorValue) &&
      this.constructor.isHexColor(this.darkModeBackgroundColorValue)
  }

  bindIntersectionObserver () {
    window.Folio.Embed.Box.intersectionObserver.observe(this.element)
  }

  unbindIntersectionObserver () {
    window.Folio.Embed.Box.intersectionObserver.unobserve(this.element)
  }

  onLoadTrigger () {
    if (this.intersectedValue) return

    this.unbindIntersectionObserver()
    this.intersectedValue = true
  }

  load () {
    if (!this.intersectedValue) return
    if (!this.folioEmbedDataValue) return

    this.iframeTargets.forEach((iframeTarget) => {
      iframeTarget.remove()
    })

    const params = new URLSearchParams()

    if (this.centeredValue) {
      params.set('centered', '1')
    }

    if (this.hasDualBackgroundColors) {
      params.set('lightModeBackgroundColor', this.lightModeBackgroundColorValue)
      params.set('darkModeBackgroundColor', this.darkModeBackgroundColorValue)
    } else if (this.backgroundColorValue) {
      params.set('backgroundColor', this.backgroundColorValue)
    }

    const queryString = params.toString()
    const src = queryString ? `/folio/embed?${queryString}` : '/folio/embed'

    this.element.insertAdjacentHTML('afterbegin', `<iframe class="f-embed-box__iframe" src="${src}" data-f-embed-box-target="iframe"></iframe>`)
  }

  intersectedValueChanged (newValue, _oldValue) {
    this.load()
  }

  folioEmbedDataValueChanged (newValue, _oldValue) {
    this.load()
  }

  onFolioColorSchemeChange (e) {
    const scheme = e.detail?.colorScheme
    if (scheme !== 'light' && scheme !== 'dark') return
    if (!this.hasDualBackgroundColors) return

    const hex = scheme === 'dark' ? this.darkModeBackgroundColorValue : this.lightModeBackgroundColorValue
    this.element.style.backgroundColor = hex
    if (this.hasLoaderTarget) {
      this.loaderTarget.style.backgroundColor = hex
    }
    const isLowLuminance = window.Folio.Embed.hexRelativeLuminance(hex) < 0.5
    this.element.classList.toggle('folio-inversed-loader', isLowLuminance)

    if (!this.hasIframeTarget) return
    if (!this.intersectedValue) return
    this.iframeTarget.contentWindow?.postMessage({
      type: 'f-embed:set-color-scheme',
      colorScheme: scheme
    }, window.origin)
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
    this.folioEmbedDataValue = e.detail.folioEmbedData
  }
})
