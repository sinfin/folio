//= require video.min

//= require ./_videojs-components

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

window.Folio.Player.create = (serializedFile, opts) => {
  const player = document.createElement('div')

  player.classList.add('f-player')
  player.classList.add(`f-player--${serializedFile.attributes.human_type}`)
  player.dataset.controller = "f-player"
  player.dataset.file = JSON.stringify(serializedFile)

  if (opts.showFormControls) {
    player.dataset.fPlayerShowFormControlsValue = "true"
  }

  const loader = document.createElement('div')
  loader.classList.add('folio-loader')
  loader.classList.add('folio-loader--transparent')

  player.appendChild(loader)

  return player
}

window.Folio.Player.bind = (el, opts) => {
  const file = JSON.parse(el.dataset.file)
  const fileAttributes = file.attributes

  if (fileAttributes.human_type !== 'audio' && fileAttributes.human_type !== 'video') {
    throw new Error(`Unsupported file human_type: ${fileAttributes.human_type}`)
  }

  const child = document.createElement(fileAttributes.human_type)
  child.src = fileAttributes.source_url
  child.autoplay = false
  child.controls = true
  child.muted = false

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
      medium: 574
    }
  })

  const controlBar = el.folioPlayer.getChild('ControlBar')

  controlBar.addChild('FolioPlayerTitle', { title: fileAttributes.file_name }, 1)

  if (fileAttributes.human_type === 'audio') {
    controlBar.addChild("FolioPlayerSeekButton", { direction: "backward" })
    controlBar.addChild("FolioPlayerSeekButton", { direction: "forward" })
  }

  if (opts.showFormControls) {
    controlBar.addChild("FolioPlayerFormControl", { action: "modal", file })
    controlBar.addChild("FolioPlayerFormControl", { action: "destroy" })
  }

  if (fileAttributes.human_type === 'video') {
    el.folioPlayer.addChild('FolioPlayerVideoSpacer', { videoSize, videoElement: el.querySelector('video') }, 0)
  }
}

window.Folio.Player.unbind = (el) => {
  if (el.folioPlayer) {
    el.folioPlayer.dispose()
    el.folioPlayer = null
  }
}

window.Folio.Stimulus.register('f-player', class extends window.Stimulus.Controller {
  static values = {
    showFormControls: Boolean,
  }

  connect () {
    window.Folio.Player.bind(this.element, { showFormControls: this.showFormControlsValue })
  }

  disconnect () {
    window.Folio.Player.unbind(this.element)
  }
})
