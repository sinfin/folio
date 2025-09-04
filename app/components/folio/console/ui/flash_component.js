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

  const modalBody = document.querySelector('.f-c-ui-modal.show .f-c-ui-modal__body')

  if (modalBody) {
    modalBody.insertAdjacentElement('beforebegin', alert)
  } else {
    const flashWrap = document.querySelector('.f-c-ui-wrap')

    if (flashWrap) {
      flashWrap.appendChild(alert)
    } else {
      console.log(alert)
    }
  }
}

window.FolioConsole.Ui.Flash.success = (content, data = {}) => {
  return window.FolioConsole.Ui.Flash.flash({
    ...data,
    content,
    variant: 'success'
  })
}

window.FolioConsole.Flash.info = (content, data = {}) => {
  return window.FolioConsole.Flash.flash({
    ...data,
    content,
    variant: 'info'
  })
}

window.FolioConsole.Flash.alert = (content, data = {}) => {
  return window.FolioConsole.Flash.flash({
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

if (window.Folio && window.Folio.MessageBus && window.Folio.MessageBus.callbacks) {
  window.Folio.MessageBus.callbacks['FolioConsole.Ui.Flash'] = (message) => {
    if (!message || message.type !== 'FolioConsole.Ui.Flash') return
    if (message.data && message.data.content) {
      window.FolioConsole.Flash.flash(message.data)
    }
  }
}
