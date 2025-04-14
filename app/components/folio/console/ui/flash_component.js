window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.Ui = window.FolioConsole.Ui || {}
window.FolioConsole.Ui.Flash = {}

window.FolioConsole.Ui.Flash.flash = (data) => {
  const contents = document.querySelectorAll('.f-c-ui-alert__content')

  for (const content of contents) {
    if (content.dataset.content === data.content) {
      const counter = parseInt(content.dataset.counter) + 1
      content.innerHTML = `${content.dataset.content} (${counter})`
      content.dataset.counter = counter

      return
    }
  }

  const alert = window.FolioConsole.Ui.Alert.create({
    ...data,
    flash: true
  })

  const modal = document.querySelector('.ReactModal--FileModal')

  if (modal) {
    modal.querySelector('.modal-content').insertBefore(alert, modal.querySelector('.modal-body'))
  } else {
    document.querySelector('.f-c-ui-flash').appendChild(alert)
  }
}

window.FolioConsole.Ui.Flash.success = (content, data = {}) => {
  return window.FolioConsole.Ui.Flash.flash({
    ...data,
    content,
    variant: 'success'
  })
}

window.FolioConsole.Ui.Flash.alert = (content, data = {}) => {
  return window.FolioConsole.Ui.Flash.flash({
    ...data,
    content,
    variant: 'danger'
  })
}

window.FolioConsole.Ui.Flash.loader = (content, data = {}) => {
  return window.FolioConsole.Ui.Flash.flash({
    ...data,
    content,
    variant: 'loader'
  })
}

window.FolioConsole.Ui.Flash.clearFlashes = () => {
  window.jQuery('.f-c-ui-flash').html('')
}

window.FolioConsole.Ui.Flash.flashMessageFromMeta = (response) => {
  if (typeof response === 'object' && response.meta && response.meta.flash) {
    if (response.meta.flash.success) {
      window.FolioConsole.Ui.Flash.success(response.meta.flash.success)
    } else if (response.meta.flash.alert) {
      window.FolioConsole.Ui.Flash.alert(response.meta.flash.alert)
    }
  }
}

window.FolioConsole.Ui.Flash.flashMessageFromApiErrors = (response) => {
  if (typeof response === 'object' && response.errors) {
    const flash = response.errors.map((obj) => `${obj.title} - ${obj.detail}`)
    window.FolioConsole.Ui.Flash.alert(flash)
  }
}
