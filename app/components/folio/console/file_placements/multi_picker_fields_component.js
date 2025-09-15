window.Folio.Stimulus.register('f-c-file-placements-multi-picker-fields', class extends window.Stimulus.Controller {
  static targets = ['iframe', 'iframeWrap']

  static values = {
    iframeSrc: String
  }

  connect () {
    // TODO move this to an intersection observer
    this.addIframeIfNeeded()
  }

  onAddEmbedClick () {
    console.log('onAddEmbedClick')
  }

  addIframeIfNeeded () {
    if (this.hasIframeTarget) return

    this.iframeWrapTarget.innerHTML = `<iframe class="f-c-file-placements-multi-picker-fields__source-iframe" data-f-c-file-placements-multi-picker-fields="iframe" src="${this.iframeSrcValue}"></iframe>`
  }
})
