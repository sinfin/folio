export function flashError (message) {
  const alert = document.createElement('div')
  alert.className = 'alert alert-dismissible fade show alert-danger'
  alert.innerHTML = `
    <button class="close" data-dismiss="alert"><span>×</span></button>
    <i class="fa fa-mr fa-times-circle"></i>
    ${message}
  `
  document.querySelector('.folio-console-flash-wrap').appendChild(alert)
}
