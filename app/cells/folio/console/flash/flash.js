window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.Flash = {}

window.FolioConsole.Flash.flash = (data) => {
  const alert = window.FolioConsole.Ui.Alert.create({
    ...data,
    flash: true
  })

  const modal = document.querySelector('.ReactModal--FileModal')

  if (modal) {
    modal.querySelector('.modal-content').insertBefore(alert, modal.querySelector('.modal-body'))
  } else {
    document.querySelector('.f-c-flash-wrap').appendChild(alert)
  }
}

window.FolioConsole.Flash.success = (content, data = {}) => {
  return window.FolioConsole.Flash.flash({
    ...data,
    content,
    variant: 'success'
  })
}

window.FolioConsole.Flash.alert = (content, data = {}) => {
  return window.FolioConsole.Flash.flash({
    ...data,
    content,
    variant: 'danger'
  })
}

window.FolioConsole.Flash.loader = (content, data = {}) => {
  return window.FolioConsole.Flash.flash({
    ...data,
    content,
    variant: 'loader'
  })
}

window.FolioConsole.Flash.clearFlashes = () => {
  $('.f-c-flash-wrap').html('')
}

window.FolioConsole.Flash.flashMessageFromMeta = (response) => {
  if (typeof response === 'object' && response.meta && response.meta.flash) {
    if (response.meta.flash.success) {
      window.FolioConsole.Flash.success(response.meta.flash.success)
    } else if (response.meta.flash.alert) {
      window.FolioConsole.Flash.alert(response.meta.flash.alert)
    }
  }
}

window.FolioConsole.Flash.flashMessageFromApiErrors = (response) => {
  if (typeof response === 'object' && response.errors) {
    const flash = response.errors.map((obj) => `${obj.title} ${obj.detail}`)
    window.FolioConsole.Flash.alert(flash)
  }
}
