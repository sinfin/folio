function flash (message, className) {
  const alert = document.createElement('div')
  alert.className = `alert alert-dismissible fade show alert-${className}`
  alert.innerHTML = `
    <button class="close" data-dismiss="alert"><span>×</span></button>
    <i class="fa fa-mr fa-times-circle"></i>
    ${message}
  `

  const modal = document.querySelector('.ReactModal--FileModal')
  if (modal) {
    modal.querySelector('.modal-content').insertBefore(alert, modal.querySelector('.modal-body'))
  } else {
    document.querySelector('.f-c-flash-wrap').appendChild(alert)
  }
}

export function flashSuccess (message) {
  flash(message, 'success')
}

export function flashError (message) {
  flash(message, 'danger')
}

export function flashMessageFromApiErrors (apiResponse) {
  let flash = apiResponse
  if (typeof apiResponse === 'object' && apiResponse.errors) {
    flash = apiResponse.errors.map((obj) => `${obj.title} ${obj.detail}`)
  }
  return flash
}
