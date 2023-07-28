window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.Ui = window.FolioConsole.Ui || {}
window.FolioConsole.Ui.Alert = {}

window.FolioConsole.Ui.Alert.iconKey = (variant) => {
  let iconKey = 'information_outline'

  if (variant === 'success') {
    iconKey = 'check_circle_outline'
  } else if (variant === 'warning' || variant === 'danger' || variant === 'alert') {
    iconKey = 'alert'
  }

  return iconKey
}

window.FolioConsole.Ui.Alert.create = (data) => {
  const variant = data.variant || 'info'

  const container = document.createElement('div')
  container.className = "f-c-ui-alert__container container-fluid"

  if (variant === 'loader') {
    const loaderWrap = document.createElement('div')
    loaderWrap.className = 'f-c-ui-alert__loader-wrap'

    const loader = document.createElement('div')
    loader.className = 'folio-loader folio-loader--tiny folio-loader--transparent folio-loader--white f-c-ui-alert__loader'

    loaderWrap.appendChild(loader)
    container.appendChild(loaderWrap)
  } else {
    const iconKey = window.FolioConsole.Ui.Alert.iconKey(variant)
    container.appendChild(window.Folio.Ui.Icon.create(iconKey))
  }

  const content = document.createElement('div')
  content.className = "f-c-ui-alert__content"
  content.innerHTML = data.content
  container.appendChild(content)

  const closeBtn = document.createElement('button')
  closeBtn.type = 'button'
  closeBtn.className = 'f-c-ui-alert__close f-c-anti-container-fluid f-c-anti-container-fluid--padding'
  closeBtn.dataset.action = 'f-c-ui-alert#close'
  closeBtn.appendChild(window.Folio.Ui.Icon.create('close'))

  container.appendChild(closeBtn)

  let className = `f-c-ui-alert f-c-ui-alert--${variant}`
  if (data.flash) { className += ' f-c-ui-alert--flash' }

  const alert = document.createElement('div')
  alert.className = className
  alert.role = 'alert'
  alert.dataset.controller = "f-c-ui-alert"

  // if (autohide) {
  //   const autohideDelay = typeof autohide === 'number' ? autohide : 5000
  //   setTimeout(() => {
  //     alert.querySelector('[data-bs-dismiss]').click()
  //   }, autohideDelay)
  // }

  if (data.data) {
    Object.keys(data.data).forEach((key) => {
      alert.dataset[key] = data.data[key]
    })
  }

  alert.appendChild(container)

  return alert
}

window.Folio.Stimulus.register('f-c-ui-alert', class extends window.Stimulus.Controller {
  close (e) {
    e.preventDefault()
    this.element.parentNode.removeChild(this.element)
  }
})
