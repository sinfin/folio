window.Folio.Stimulus.register('f-c-form-errors', class extends window.Stimulus.Controller {
  static targets = ['button']

  connect () {
    const form = this.element.closest('form')
    if (!form) return

    const nodes = form.querySelectorAll('.form-group-invalid, .form-group.has-danger, .form-control.is-invalid')
    if (!nodes.length) return

    for (const node of nodes) {
      const input = node.classList.contains('form-control') ? node : node.querySelector('.form-control')
      if (!input) continue

      const formGroup = node.classList.contains('form-control')
        ? (input.closest('.form-group') || input.parentElement)
        : node

      let key = input.name || input.getAttribute('data-name') // react_ordered_multiselect
      if (!key) continue

      key = key.match(/\[(.+)\]$/)
      if (!key) continue

      key = key[1]
      if (!key) continue

      key = key.replace('_attributes', '').replace(/\]\[\d*\]\[/, '.')
      let found = false

      this.buttonTargets.forEach((buttonTarget) => {
        if (found) return
        if (!buttonTarget.classList.contains('f-c-form-errors__button--hidden')) return
        const btnKey = buttonTarget.dataset.errorField
        if (btnKey !== key && !key.endsWith(`.${btnKey}`)) return
        buttonTarget.classList.remove('f-c-form-errors__button--hidden')
        buttonTarget.formGroup = formGroup
        found = true
      })
    }
  }

  disconnect () {
    this.buttonTargets.forEach((buttonTarget) => {
      delete buttonTarget.formGroup
    })
  }

  onButtonClick (e) {
    e.preventDefault()

    const btn = e.currentTarget

    if (!btn.formGroup) return

    const tab = btn.formGroup.closest('.tab-pane')

    if (tab && !tab.classList.contains('active')) {
      for (const tabLink of document.querySelectorAll('.nav-tabs .nav-link')) {
        if (tabLink.href.split('#').pop() === tab.id) {
          tabLink.click()
          break
        }
      }
    }

    btn.formGroup.scrollIntoView({ behavior: 'smooth', block: 'center' })

    if (window.FolioConsole && window.FolioConsole.DangerBoxShadowBlink && window.FolioConsole.DangerBoxShadowBlink.blinkFormGroup) {
      window.FolioConsole.DangerBoxShadowBlink.blinkFormGroup(btn.formGroup)
    }

    const input = btn.formGroup.querySelector('.form-control')
    if (input) input.focus()
  }
})
