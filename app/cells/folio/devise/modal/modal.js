//= require folio/form_to_hash

window.Folio.Stimulus.register('f-devise-modal-form', class extends window.Stimulus.Controller {
  connect () {
    const form = this.element.querySelector('.f-devise-modal__form')

    if (form) {
      form.dataset.action = "f-devise-modal-form#onSubmit"
    }
  }

  onSubmit (e) {
    e.preventDefault()

    const form = e.target
    form.classList.add('f-devise-modal__form--loading')

    const errors = form.querySelector('.f-devise__errors')
    errors.innerHTML = ""

    const data = window.Folio.formToHash(form)
    const reenable = () => {
      form.classList.remove('f-devise-modal__form--loading')
      const submits = form.querySelectorAll('[type="submit"]')

      for (const submit of submits) {
        submit.disabled = false
      }
    }

    window.Folio.Api.apiPost(form.action, data)
      .then((res) => {
        if (res.errors) {
          errors.innerHTML = res.errors.map((h) => h.detail).join("<br>")
          reenable()
        } else {
          if (res.data && res.data.url) {
            window.location.href = res.data.url
          } else {
            window.location.reload()
          }
        }
      })
      .catch((err) => {
        window.alert(form.dataset.failure)
        reenable()
      })
  }
})
