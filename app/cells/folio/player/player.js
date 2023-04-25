//= require video.min

window.Folio = window.Folio || {}
window.Folio.Player = window.Folio.Player || {}

window.Folio.Player.themeColor = window.Folio.Player.themeColor || '#000000'

window.Folio.Player.defaultOptions = {
  video: {},
  audio: {
    playbackRates: [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2]
  }
}

class FolioPlayerTitleComponent extends window.videojs.getComponent('Component') {
  constructor (player, options = {}) {
    super(player, options)
    if (options.title) this.updateTextContent(options.title)
  }

  createEl () {
    return videojs.dom.createEl('div', { className: 'vjs-folio-player-title' })
  }

  updateTextContent (text) {
    window.videojs.emptyEl(this.el())
    window.videojs.appendContent(this.el(), text)
  }
}

window.videojs.registerComponent('FolioPlayerTitle', FolioPlayerTitleComponent)

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
    opts = children[i].options && children[i].options()
    if (opts && opts.name === "ControlBar") {
      el.folioPlayer.addChild('FolioPlayerTitle', { title: fileAttributes.file_name }, i)
      break
    }
  }
}

window.Folio.Player.unbind = (el) => {
  // if (el.folioPlayer) {
  //   el.folioPlayer.destroy()
  //   el.folioPlayer = null
  // }
}

window.Folio.Stimulus.register('f-player', class extends window.Stimulus.Controller {
  connect () {
    window.Folio.Player.bind(this.element)
  }

  disconnect () {
    window.Folio.Player.unbind(this.element)
  }
})
