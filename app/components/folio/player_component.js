//= require folio/waveform
//= require folio/capitalize

window.Folio = window.Folio || {}
window.Folio.Player = window.Folio.Player || {}

window.Folio.Player.themeColor = window.Folio.Player.themeColor || '#000000'

window.Folio.Player.defaultOptions = {
  video: {},
  audio: {
    playbackRates: [2, 1.5, 1.25, 1, 0.75, 0.5, 0.25],
    controlBar: {
      fullscreenToggle: false
    }
  }
}

window.Folio.Player.registerComponents = () => {
  if (window.Folio.Player.registeredVideoJsComponents) return

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

      attributes['data-action'] = `${this.options_.formControlsController || 'f-c-files-picker'}#onFormControl${window.Folio.capitalize(this.options_.action)}Click`

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

  window.Folio.Player.registeredVideoJsComponents = true
}

window.Folio.Player.create = (serializedFile, opts) => {
  const player = document.createElement('div')

  player.classList.add('f-player')
  player.classList.add(`f-player--${serializedFile.attributes.human_type}`)
  player.dataset.controller = 'f-player'
  player.dataset.fPlayerFileJsonValue = JSON.stringify(serializedFile)

  if (opts.showFormControls) {
    player.dataset.fPlayerShowFormControlsValue = 'true'
  }

  if (opts.formControlsController) {
    player.dataset.fPlayerFormControlsControllerValue = opts.formControlsController
  }

  const loader = document.createElement('div')
  loader.classList.add('folio-loader')
  loader.classList.add('folio-loader--transparent')

  player.appendChild(loader)

  return player
}

window.Folio.Player.innerBind = (el, opts, file) => {
  const fileAttributes = file.attributes

  if (fileAttributes.human_type !== 'audio' && fileAttributes.human_type !== 'video') {
    throw new Error(`Unsupported file human_type: ${fileAttributes.human_type}`)
  }

  const child = document.createElement(fileAttributes.human_type)
  child.autoplay = false
  child.controls = true
  child.muted = false

  const source = document.createElement('source')
  source.type = fileAttributes.player_source_mime_type
  source.src = fileAttributes.mux_source_url || fileAttributes.source_url

  child.appendChild(source)

  const videoSize = { width: 1600, height: 900 }

  if (fileAttributes.human_type === 'video') {
    if (fileAttributes.file_width && fileAttributes.file_height) {
      videoSize.width = fileAttributes.file_width
      videoSize.height = fileAttributes.file_height
    }
  }

  child.width = videoSize.width
  child.height = videoSize.height

  child.classList.add('video-js')
  child.classList.add('f-player__player')

  el.innerHTML = ''
  el.appendChild(child)

  el.folioPlayer = window.videojs(child, {
    ...window.Folio.Player.defaultOptions[fileAttributes.human_type],
    controls: true,
    autoplay: false,
    preload: 'auto',
    responsive: true,
    breakpoints: {
      xsmall: 360,
      medium: 554
    }
  })

  const controlBar = el.folioPlayer.getChild('ControlBar')

  controlBar.addChild('FolioPlayerTitle', { title: fileAttributes.file_name }, 1)

  if (fileAttributes.human_type === 'audio') {
    controlBar.addChild('FolioPlayerSeekButton', { direction: 'backward' })
    controlBar.addChild('FolioPlayerSeekButton', { direction: 'forward' })
  }

  if (opts.showFormControls) {
    controlBar.addChild('FolioPlayerFormControl', { action: 'modal', file, formControlsController: opts.formControlsController })
    controlBar.addChild('FolioPlayerFormControl', { action: 'destroy', file, formControlsController: opts.formControlsController })

    el.classList.add('f-player--with-form-controls')
  }

  if (fileAttributes.human_type === 'video') {
    el.folioPlayer.addChild('FolioPlayerVideoSpacer', { videoSize, videoElement: el.querySelector('video') }, 0)
  } else if (fileAttributes.human_type === 'audio') {
    el.querySelector('.vjs-progress-control').classList.add('vjs-progress-control--waveform')

    el.folioPlayer.on('playerresize', (e) => {
      window.Folio.Player.waveform(fileAttributes.id || 0, el)
    })
  }

  const errorDisplay = el.folioPlayer.getChild('ErrorDisplay')

  errorDisplay.el_.appendChild(window.Folio.Ui.Icon.create('alert', { class: 'f-player__error-ico' }))

  el.classList.add('f-player--bound')
}

window.Folio.Player.bind = (el, opts) => {
  window.Folio.RemoteScripts.run({
    key: 'video-js',
    url: 'https://cdnjs.cloudflare.com/ajax/libs/video.js/8.22.0/video.min.js',
    cssUrls: ['https://cdnjs.cloudflare.com/ajax/libs/video.js/8.22.0/video-js.min.css']
  }, () => {
    window.Folio.Player.registerComponents()

    let file = JSON.parse(el.dataset.fPlayerFileJsonValue)

    if (file.attributes.jw_player_api_url && !file.attributes.handled_jw_player_api_url) {
      window.Folio.Api.apiGet(file.attributes.jw_player_api_url)
        .then((res) => {
          if (res && res.data && res.data.attributes) {
            file = {
              ...file,
              attributes: {
                ...file.attributes,
                ...res.data.attributes,
                handled_jw_player_api_url: true
              }
            }

            el.dataset.fPlayerFileJsonValue = JSON.stringify(file)
            window.Folio.Player.innerBind(el, opts, file)
          }
        })
        .catch((e) => {
          console.error('Failed to get jw_player_api_url')
          window.Folio.Player.innerBind(el, opts, file)
        })
    } else {
      window.Folio.Player.innerBind(el, opts, file)
    }
  }, () => {
    console.error('Failed loading Video.js from CDN')
  })
}

window.Folio.Player.unbind = (el) => {
  if (el.folioPlayer) {
    el.folioPlayer.dispose()
    el.folioPlayer = null
  }

  el.classList.remove('f-player--bound')
}

window.Folio.Player.waveform = (id, el) => {
  const existing = el.querySelectorAll('.f-player__waveform-wrap')

  for (let i = 0; i < existing.length; i += 1) {
    existing[i].parentNode.removeChild(existing[i])
  }

  const control = el.querySelector('.vjs-progress-control')
  const progress = control.querySelector('.vjs-play-progress')
  control.classList.add('vjs-progress-control--waveform')

  window.setTimeout(() => {
    const progressSvg = window.Folio.waveform({
      id,
      width: control.clientWidth,
      height: 20,
      class: 'f-player__waveform'
    })

    const backgroundSvg = progressSvg.cloneNode(true)
    const backgroundWrap = document.createElement('div')
    backgroundWrap.classList.add('f-player__waveform-wrap')
    backgroundWrap.classList.add('f-player__waveform-wrap--background')
    backgroundWrap.appendChild(backgroundSvg)
    control.appendChild(backgroundWrap)

    const progressWrap = document.createElement('div')
    progressWrap.classList.add('f-player__waveform-wrap')
    progressWrap.classList.add('f-player__waveform-wrap--progress')
    progressWrap.appendChild(progressSvg)

    progress.appendChild(progressWrap)
  }, 0)
}

window.Folio.Stimulus.register('f-player', class extends window.Stimulus.Controller {
  static values = {
    showFormControls: Boolean,
    fileJson: String,
    formControlsController: { type: String, default: 'f-c-files-picker' }
  }

  connect () {
    window.Folio.Player.bind(this.element, {
      showFormControls: this.showFormControlsValue,
      formControlsController: this.formControlsControllerValue
    })
  }

  disconnect () {
    window.Folio.Player.unbind(this.element)
  }
})
