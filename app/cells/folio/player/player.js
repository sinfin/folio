//= require video.min

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

window.Folio.Player.create = (serializedFile) => {
  const player = document.createElement('div')

  player.classList.add('f-player')
  player.dataset.controller = "f-player"
  player.dataset.file = JSON.stringify(serializedFile)

  const loader = document.createElement('div')
  loader.classList.add('folio-loader')
  loader.classList.add('folio-loader--transparent')

  player.appendChild(loader)

  return player
}

class FolioPlayerTitleComponent extends window.videojs.getComponent('Component') {
  constructor (player, options = {}) {
    super(player, options)
    if (options.title) this.updateTextContent(options.title)
  }

  createEl () {
    return window.videojs.dom.createEl('div', { className: 'vjs-folio-player-title' })
  }

  updateTextContent (text) {
    window.videojs.emptyEl(this.el())
    window.videojs.appendContent(this.el(), text)
  }
}

window.videojs.registerComponent('FolioPlayerTitle', FolioPlayerTitleComponent)

class FolioPlayerSeekButtonComponent extends window.videojs.getComponent('Button') {
  buildCSSClass () {
    return `vjs-control vjs-folio-player-seek-button vjs-folio-player-seek-button--${this.options_.direction}`
  }

  handleClick (e) {
    const now = this.player_.currentTime();

    if (this.options_.direction === 'forward') {
      this.player_.currentTime(Math.min(now + 15, this.player_.duration()));
    } else {
      this.player_.currentTime(Math.max(0, now - 15));
    }
  }
}

window.videojs.registerComponent('FolioPlayerSeekButton', FolioPlayerSeekButtonComponent)

window.Folio.Player.bind = (el) => {
  const fileAttributes = JSON.parse(el.dataset.file).attributes

  if (fileAttributes.human_type !== 'audio' && fileAttributes.human_type !== 'video') {
    throw new Error(`Unsupported file human_type: ${fileAttributes.human_type}`)
  }

  const child = document.createElement(fileAttributes.human_type)
  child.src = fileAttributes.source_url
  child.autoplay = false
  child.controls = true
  child.muted = false

  if (fileAttributes.human_type === 'video') {
    child.height = 900
    child.width = 1600
  }

  child.classList.add('video-js')
  child.classList.add('f-player__player')
  child.classList.add(`f-player__player--${fileAttributes.human_type}`)

  el.innerHTML = ''
  el.appendChild(child)

  el.folioPlayer = window.videojs(child, {
    ...window.Folio.Player.defaultOptions[fileAttributes.human_type],
    controls: true,
    autoplay: false,
    preload: 'auto'
  })

  const children = el.folioPlayer.children()

  for (let i = 0; i < children.length; i += 1) {
    const opts = children[i].options && children[i].options()
    if (opts && opts.name === 'ControlBar') {
      el.folioPlayer.addChild('FolioPlayerTitle', { title: fileAttributes.file_name }, i)
      break
    }
  }

  const controlBar = el.folioPlayer.getChild('ControlBar')
  controlBar.addChild("FolioPlayerSeekButton", { direction: "backward" })
  controlBar.addChild("FolioPlayerSeekButton", { direction: "forward" })
}

window.Folio.Player.unbind = (el) => {
  if (el.folioPlayer) {
    el.folioPlayer.dispose()
    el.folioPlayer = null
  }
}

window.Folio.Stimulus.register('f-player', class extends window.Stimulus.Controller {
  connect () {
    window.Folio.Player.bind(this.element)
  }

  disconnect () {
    window.Folio.Player.unbind(this.element)
  }
})
