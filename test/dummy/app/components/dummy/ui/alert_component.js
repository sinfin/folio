window.Dummy = window.Dummy || {}
window.Dummy.Ui = window.Dummy.Ui || {}
window.Dummy.Ui.Alert = {}

window.Dummy.Ui.Alert.iconKey = (variant) => {
  let iconKey = 'info'

  if (variant === 'success') {
    iconKey = 'check'
  } else if (variant === 'warning' || variant === 'danger' || variant === 'alert') {
    iconKey = 'alert_triangle'
  }

  return iconKey
}

window.Dummy.Ui.Alert.create = (data) => {
  const variant = data.variant || 'info'

  const container = document.createElement('div')
  container.className = "d-ui-alert__container container-fluid"

  if (variant === 'loader') {
    const loaderWrap = document.createElement('div')
    loaderWrap.className = 'd-ui-alert__loader-wrap'

    const loader = document.createElement('div')
    loader.className = 'folio-loader folio-loader--tiny folio-loader--transparent d-ui-alert__loader'

    loaderWrap.appendChild(loader)
    container.appendChild(loaderWrap)
  } else {
    const iconKey = window.Dummy.Ui.Alert.iconKey(variant)
    container.appendChild(window.Dummy.Ui.Icon.create(iconKey))
  }

  const content = document.createElement('div')
  content.className = "d-ui-alert__content"
  content.innerHTML = data.content
  container.appendChild(content)

  const closeBtn = document.createElement('button')
  closeBtn.type = 'button'
  closeBtn.className = 'd-ui-alert__close d-anti-container-fluid d-anti-container-fluid--padding'
  closeBtn.dataset.action = 'd-ui-alert#close'
  closeBtn.appendChild(window.Dummy.Ui.Icon.create('close'))

  container.appendChild(closeBtn)

  let className = `d-ui-alert d-ui-alert--${variant}`
  if (data.flash) { className += ' d-ui-alert--flash' }

  const alert = document.createElement('div')
  alert.className = className
  alert.role = 'alert'
  alert.dataset.controller = "d-ui-alert"

  if (data.data) {
    Object.keys(data.data).forEach((key) => {
      alert.dataset[key] = data.data[key]
    })
  }

  alert.appendChild(container)

  return alert
}

window.Folio.Stimulus.register('d-ui-alert', class extends window.Stimulus.Controller {
  close (e) {
    e.preventDefault()
    this.element.parentNode.removeChild(this.element)
  }
})
