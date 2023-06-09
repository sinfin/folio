window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.Ui = window.FolioConsole.Ui || {}
window.FolioConsole.Ui.Button = window.FolioConsole.Ui.Button || {}

window.FolioConsole.Ui.Button.create = (model) => {
  let element

  if (model.href) {
    element = document.createElement('a')
    element.href = model.href
  } else {
    element = document.createElement('button')
    element.type = model.type || 'button'
  }

  element.classList.add('f-c-ui-button', 'btn', `btn-${model.variant || 'primary'}`)

  if (model.class) {
    element.classList.add(model.class)
  }

  if (model.icon) {
    element.appendChild(window.Folio.Ui.Icon.create(model.icon, { class: "f-c-ui-button__icon" }))
  }

  if (model.label) {
    const label = document.createElement('span')
    label.classList.add('f-c-ui-button__label')
    label.innerHTML = model.label
    element.appendChild(label)
  }

  if (model.rightIcon) {
    element.appendChild(window.Folio.Ui.Icon.create(model.rightIcon, { class: "f-c-ui-button__right-icon" }))
  }

  return element
}
