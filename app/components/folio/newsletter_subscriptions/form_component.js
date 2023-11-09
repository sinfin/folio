window.Folio.Stimulus.register('f-newsletter-subscriptions-form', class extends window.Stimulus.Controller {
  static classes = ["submitting", "persisted", "invalid"]

  connect () {
    if (this.element.classList.contains(this.persistedClass)) {
      this.element.dispatchEvent(new window.CustomEvent('folio:success', { bubbles: true }))
    } else if (this.element.classList.contains(this.invalidClass)) {
      this.element.dispatchEvent(new window.CustomEvent('folio:failure', { bubbles: true }))
    }
  }

  onSubmit (e) {
    e.preventDefault()

    if (this.element.classList.contains(this.submittingClass)) return

    this.element.classList.add(this.submittingClass)

    const data = window.Folio.formToHash(e.target)

    window.Folio.Api.apiPost(e.target.action, data).then((res) => {
      this.element.outerHTML = res.data

      // if ($response.find('.f-newsletter-subscriptions-form__message').length) {
      //   $response.trigger('folio:success')
      // } else {
      //   $response.trigger('folio:failure')
      // }
    }).catch((err) => {
      console.error(err)
      this.element.classList.remove(this.submittingClass)
    })
  }
})
