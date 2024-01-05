window.Folio.Stimulus.register('f-c-site-user-links-fields', class extends window.Stimulus.Controller {
  static targets = ["link"]

  onAnyChange () {
    this.toggleDisabledOnCheckboxes()
  }

  toggleDisabledOnCheckboxes () {
    this.linkTargets.forEach((linkTarget) => {
      const checked = linkTarget.querySelector('.f-c-site-user-links-fields__link-head .form-check-input').checked
      const inputs = linkTarget.querySelectorAll('.f-c-site-user-links-fields__link-roles .form-check-input')

      if (checked) {
        for (const input of inputs) {
          input.disabled = false
        }
      } else {
        for (const input of inputs) {
          input.checked = false
          input.disabled = true
        }
      }
    })
  }
})
