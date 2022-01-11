window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.Flash = {}

window.FolioConsole.Flash.flash = (msg, type = 'success', autohide = false) => {
  let className = 'alert-danger'
  let icon = 'fa fa-mr fa-times-circle'

  if (type === 'success') {
    className = 'alert-success'
    icon = 'fa fa-mr fa-check-circle'
  }

  const $flash = $(`
    <div class="alert alert-dismissible fade show ${className}" role="alert">
      <button class="close" data-dismiss="alert"><span>&times;</span></button>
      <i class="${icon}"></i>
      ${msg}
    </div>
  `)

  const modal = document.querySelector('.ReactModal--FileModal')

  if (modal) {
    modal.querySelector('.modal-content').insertBefore($flash[0], modal.querySelector('.modal-body'))
  } else {
    $('.f-c-flash-wrap').append($flash)
  }

  if (autohide) {
    const autohideDelay = typeof autohide === "number" ? autohide : 5000
    setTimeout(() => { $flash.find('[data-dismiss]').click() }, autohideDelay)
  }
}

window.FolioConsole.Flash.success = (msg, autohide = false) => {
  return window.FolioConsole.Flash.flash(msg, 'success', autohide)
}

window.FolioConsole.Flash.alert = (msg, autohide = false) => {
  return window.FolioConsole.Flash.flash(msg, 'alert', autohide)
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
