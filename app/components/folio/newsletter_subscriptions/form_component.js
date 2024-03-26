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
      const responseData = res.data
      this.element.outerHTML = responseData

      if (responseData.includes('f-newsletter-subscriptions-form__message')) {
        this.element.dispatchEvent(new window.CustomEvent('folio:success', { bubbles: true }))
      } else {
        this.element.dispatchEvent(new window.CustomEvent('folio:failure', { bubbles: true }))
      }
    }).catch((err) => {
      console.error(err)
      this.element.classList.remove(this.submittingClass)
    })
  }
})
