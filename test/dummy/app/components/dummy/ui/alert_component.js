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

window.Dummy.Ui.Alert.close = (alert) => {
  alert.remove()
}

window.Dummy.Ui.Alert.create = (data) => {
  const duplicates = []
  let count = 1

  const variant = data.variant || 'info'

  for (const existing of document.querySelectorAll('.d-ui-alert')) {
    if (existing.dataset.variant === variant && existing.dataset.content === data.content) {
      duplicates.push(existing)
      count += parseInt(existing.dataset.count)
      window.Dummy.Ui.Alert.close(existing)
    }
  }

  const container = document.createElement('div')
  container.className = 'd-ui-alert__container container-fluid'

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
  content.className = 'd-ui-alert__content'
  content.innerHTML = data.content

  if (count > 1) {
    content.innerHTML += ` (${count})`
  }

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
  alert.dataset.controller = 'd-ui-alert'

  if (data.data) {
    Object.keys(data.data).forEach((key) => {
      alert.dataset[key] = data.data[key]
    })
  }

  alert.appendChild(container)

  alert.dataset.content = data.content
  alert.dataset.variant = variant
  alert.dataset.count = count

  return alert
}

window.Folio.Stimulus.register('d-ui-alert', class extends window.Stimulus.Controller {
  close (e) {
    e.preventDefault()
    this.element.parentNode.removeChild(this.element)
  }
})
