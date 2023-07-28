window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.Ui = window.FolioConsole.Ui || {}
window.FolioConsole.Ui.Buttons = window.FolioConsole.Ui.Buttons || {}

window.FolioConsole.Ui.Buttons.create = (models) => {
  const wrap = document.createElement('div')
  wrap.className = "f-c-ui-buttons"

  models.forEach((model) => {
    wrap.appendChild(window.FolioConsole.Ui.Button.create(model))
  })

  return wrap
}
