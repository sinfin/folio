window.Dummy = window.Dummy || {}
window.Dummy.Ui = window.Dummy.Ui || {}
window.Dummy.Ui.Flash = {}

window.Dummy.Ui.Flash.flash = (data) => {
  const alert = window.Dummy.Ui.Alert.create({
    ...data,
    flash: true,
  })

  document.querySelector('.d-ui-flash').appendChild(alert)
}

window.Dummy.Ui.Flash.success = (content, data = {}) => {
  return window.Dummy.Ui.Flash.flash({
    ...data,
    content,
    variant: 'success',
  })
}

window.Dummy.Ui.Flash.alert = (content, data = {}) => {
  return window.Dummy.Ui.Flash.flash({
    ...data,
    content,
    variant: 'danger',
  })
}

window.Dummy.Ui.Flash.loader = (content, data = {}) => {
  return window.Dummy.Ui.Flash.flash({
    ...data,
    content,
    variant: 'loader',
  })
}

window.Dummy.Ui.Flash.clearFlashes = () => {
  document.querySelector('.d-ui-flash').innerHTML = ""
}

window.Dummy.Ui.Flash.flashMessageFromMeta = (response) => {
  if (typeof response === 'object' && response.meta && response.meta.flash) {
    if (response.meta.flash.success) {
      window.Dummy.Ui.Flash.success(response.meta.flash.success)
    } else if (response.meta.flash.alert) {
      window.Dummy.Ui.Flash.alert(response.meta.flash.alert)
    }
  }
}

window.Dummy.Ui.Flash.flashMessageFromApiErrors = (response) => {
  if (typeof response === 'object' && response.errors) {
    const flash = response.errors.map((obj) => `${obj.title} ${obj.detail}`)
    window.Dummy.Ui.Flash.alert(flash)
  }
}
