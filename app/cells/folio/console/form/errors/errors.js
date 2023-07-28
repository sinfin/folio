window.Folio.Stimulus.register('f-c-form-errors', class extends window.Stimulus.Controller {
  static targets = ['button']

  connect () {
    const form = this.element.closest('form')
    const formGroups = form.querySelectorAll('.form-group-invalid, .form-group.has-danger')

    if (!formGroups.length) return

    for (const formGroup of formGroups) {
      const input = formGroup.querySelector('.form-control')

      if (!input) continue

      let key = input.name
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
        if (buttonTarget.dataset.errorField !== key) return
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

    btn.formGroup.scrollIntoView()

    if (btn.formGroup.dataset.controller) {
      btn.formGroup.dataset.controller += ' f-c-danger-box-shadow-blink'
    } else {
      btn.formGroup.dataset.controller = 'f-c-danger-box-shadow-blink'
    }
  }
})
