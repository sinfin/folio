//= require folio/capitalize

class FolioPlayerVideoSpacerComponent extends window.videojs.getComponent('Component') {
  constructor (player, options = {}) {
    super(player, options)
    this.addSpacer()
    this.appendVideo()
  }

  createEl () {
    return window.videojs.dom.createEl('div', { className: 'vjs-folio-player-video-spacer' })
  }

  appendVideo () {
    window.setTimeout(() => {
      this.el().appendChild(this.options_.videoElement)
    }, 0)
  }

  addSpacer () {
    const spacer = document.createElement('div')
    spacer.classList.add('vjs-folio-player-video-spacer__spacer')
    spacer.style.paddingTop = `${Math.round(100 * (100 * this.options_.videoSize.height / this.options_.videoSize.width)) / 100}%`
    this.el().appendChild(spacer)
  }
}

window.videojs.registerComponent('FolioPlayerVideoSpacer', FolioPlayerVideoSpacerComponent)

class FolioPlayerTitleComponent extends window.videojs.getComponent('Component') {
  constructor (player, options = {}) {
    super(player, options)
    if (options.title) this.updateTextContent(options.title)
  }

  createEl () {
    return window.videojs.dom.createEl('div', { className: 'vjs-folio-player-title' })
  }

  updateTextContent (text) {
    window.videojs.dom.emptyEl(this.el())
    window.videojs.dom.appendContent(this.el(), text)
  }
}

window.videojs.registerComponent('FolioPlayerTitle', FolioPlayerTitleComponent)

class FolioPlayerSeekButtonComponent extends window.videojs.getComponent('Button') {
  buildCSSClass () {
    return `vjs-control vjs-folio-player-seek-button vjs-folio-player-seek-button--${this.options_.direction}`
  }

  handleClick (e) {
    const now = this.player_.currentTime()

    if (this.options_.direction === 'forward') {
      this.player_.currentTime(Math.min(now + 15, this.player_.duration()))
    } else {
      this.player_.currentTime(Math.max(0, now - 15))
    }
  }
}

window.videojs.registerComponent('FolioPlayerSeekButton', FolioPlayerSeekButtonComponent)

class FolioPlayerFormControlComponent extends window.videojs.getComponent('Button') {
  buildCSSClass () {
    return `vjs-control vjs-folio-player-form-control vjs-folio-player-form-control--${this.options_.action}`
  }

  createEl (tag, props = {}, attributes = {}) {
    tag = 'button'

    props = Object.assign({
      className: this.buildCSSClass()
    }, props)

    // Add attributes for button element
    attributes = Object.assign({

      // Necessary since the default button type is "submit"
      type: 'button'
    }, attributes)

    attributes['data-action'] = `${this.options_.formControlsController || 'f-c-file-picker'}#onFormControl${window.Folio.capitalize(this.options_.action)}Click`

    if (this.options_.file) {
      attributes['data-file'] = JSON.stringify(this.options_.file)
    }

    const el = window.videojs.dom.createEl(tag, props, attributes)

    el.appendChild(window.videojs.dom.createEl('span', {
      className: 'vjs-icon-placeholder'
    }, {
      'aria-hidden': true
    }))

    this.createControlTextEl(el)

    return el
  }
}

window.videojs.registerComponent('FolioPlayerFormControl', FolioPlayerFormControlComponent)
