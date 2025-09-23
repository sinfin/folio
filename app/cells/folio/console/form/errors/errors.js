window.Folio.Stimulus.register('f-c-form-errors', class extends window.Stimulus.Controller {
  static targets = ['button']

  connect () {
    const form = this.element.closest('form')
    if (!form) return

    const nodes = form.querySelectorAll('.form-group-invalid, .form-group.has-danger, .form-control.is-invalid, .f-c-file-placements-multi-picker-fields-placement .invalid-feedback')
    if (!nodes.length) return

    for (const node of nodes) {
      let inputOrDiv

      if (node.classList.contains('form-control')) {
        inputOrDiv = node
      } else if (node.classList.contains('invalid-feedback')) {
        inputOrDiv = node
      } else {
        inputOrDiv = node.querySelector('.form-control')
      }

      if (!inputOrDiv) continue

      const formGroup = node.classList.contains('form-control')
        ? (inputOrDiv.closest('.form-group') || inputOrDiv.parentElement)
        : node

      let key = inputOrDiv.name || inputOrDiv.getAttribute('data-name') // react_ordered_multiselect
      if (!key) continue

      if (!inputOrDiv.classList.contains('invalid-feedback')) {
        key = key.match(/\[(.+)\]$/)
        if (!key) continue

        key = key[1]
        if (!key) continue

        key = key.replace('_attributes', '').replace(/\]\[\d*\]\[/, '.')
      }

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
      const navLink = document.querySelector(`.f-c-ui-tabs__nav-link[data-bs-target="#${tab.id}"]`)
      if (navLink) {
        navLink.click()
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
