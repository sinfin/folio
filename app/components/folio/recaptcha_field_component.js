window.Folio.Stimulus.register('f-recaptcha-field', class extends window.Stimulus.Controller {
  connect () {
    if (window.grecaptcha && window.grecaptcha.render) {
      const target = this.element.querySelector('.g-recaptcha')

      if (target && target.innerHTML === "") {
        window.grecaptcha.render(target)
      }
    }
  }
})
