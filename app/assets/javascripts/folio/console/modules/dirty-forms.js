window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.DirtyForms = window.FolioConsole.DirtyForms || {}

window.FolioConsole.DirtyForms.handled = false

window.FolioConsole.DirtyForms.onMessage = (e) => {
  if (e.origin === window.origin && e.data.type === 'setFormAsDirty') {
    const form = document.querySelector('.f-c-simple-form-with-atoms')

    if (form) {
      window.FolioConsole.DirtyForms.handle(form)
    }
  }
}

window.FolioConsole.DirtyForms.onChange = (e) => {
  const simpleForm = e.target.closest('.simple_form')

  if (simpleForm) {
    window.FolioConsole.DirtyForms.handle(simpleForm)
  }
}

window.FolioConsole.DirtyForms.onBeforeUnload = (e) => {
  e.preventDefault()
  e.returnValue = 'Changes you made may not be saved.'
  return 'Changes you made may not be saved.'
}

window.FolioConsole.DirtyForms.unbind = () => {
  if (!window.FolioConsole.DirtyForms.handled) return
  window.removeEventListener('beforeunload', window.FolioConsole.DirtyForms.onBeforeUnload)
}

window.FolioConsole.DirtyForms.handle = (form) => {
  if (window.FolioConsole.DirtyForms.handled) return
  window.FolioConsole.DirtyForms.handled = true

  document.removeEventListener('change', window.FolioConsole.DirtyForms.onChange)
  window.removeEventListener('message', window.FolioConsole.DirtyForms.onMessage, false)

  form.classList.add('simple_form--dirty')
  window.addEventListener('beforeunload', window.FolioConsole.DirtyForms.onBeforeUnload)
}

window.addEventListener('message', window.FolioConsole.DirtyForms.onMessage, false)

document.addEventListener('change', window.FolioConsole.DirtyForms.onChange)

document.addEventListener('submit', () => {
  window.FolioConsole.DirtyForms.unbind()
})
