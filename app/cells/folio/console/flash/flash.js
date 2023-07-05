window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.Flash = {}

window.FolioConsole.Flash.flash = (msg, type = 'success', autohide = false, data = {}) => {
  let className = 'alert alert-dismissible fade show'
  let iconKey = 'alert'

  if (type === 'success') {
    className += ' alert-success'
    iconKey = 'check_circle_outline'
  } else if (type === 'info') {
    className += ' alert-info'
    iconKey = 'information_outline'
  } else if (type === 'pending') {
    className += ' alert-pending'
  } else {
    className += ' alert-danger'
  }

  const flash = document.createElement('div')
  flash.className = className
  flash.role = 'alert'

  Object.keys(data).forEach((key) => {
    flash.dataset[key] = data[key]
  })

  if (type === 'pending') {
    const loaderWrap = document.createElement('div')
    loaderWrap.className = 'f-c-flash-wrap__loader-wrap'

    const loader = document.createElement('div')
    loader.className = 'folio-loader folio-loader--tiny folio-loader--transparent folio-loader--white f-c-flash-wrap__loader'

    loaderWrap.appendChild(loader)
    flash.appendChild(loaderWrap)
  } else {
    flash.appendChild(window.Folio.Ui.Icon.create(iconKey))
  }

  flash.appendChild(document.createTextNode(msg))

  const closeBtn = document.createElement('button')
  closeBtn.type = 'button'
  closeBtn.className = 'close'
  closeBtn.dataset.dismiss = 'alert'
  closeBtn.appendChild(window.Folio.Ui.Icon.create('close'))

  flash.appendChild(closeBtn)

  const modal = document.querySelector('.ReactModal--FileModal')

  if (modal) {
    modal.querySelector('.modal-content').insertBefore(flash, modal.querySelector('.modal-body'))
  } else {
    document.querySelector('.f-c-flash-wrap').appendChild(flash)
  }

  if (autohide) {
    const autohideDelay = typeof autohide === 'number' ? autohide : 5000
    setTimeout(() => {
      flash.querySelector('[data-bs-dismiss]').click()
    }, autohideDelay)
  }
}

window.FolioConsole.Flash.success = (msg, autohide = false, data = {}) => {
  return window.FolioConsole.Flash.flash(msg, 'success', autohide, data)
}

window.FolioConsole.Flash.alert = (msg, autohide = false, data = {}) => {
  return window.FolioConsole.Flash.flash(msg, 'alert', autohide, data)
}

window.FolioConsole.Flash.pending = (msg, autohide = false, data = {}) => {
  return window.FolioConsole.Flash.flash(msg, 'pending', autohide, data)
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
