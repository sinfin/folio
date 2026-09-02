window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.AasmEmailModal = window.FolioConsole.AasmEmailModal || {}

// Called by the f-c-state controller when the clicked event declares
// `email_modal: true`. detail carries the trigger's data attributes.
window.FolioConsole.AasmEmailModal.open = (detail) => {
  const modal = document.querySelector('.f-c-aasm-email-modal')

  if (!modal) {
    throw new Error('Missing .f-c-aasm-email-modal. Render Folio::Console::Aasm::EmailModalComponent in the console layout.')
  }

  modal.dispatchEvent(new window.CustomEvent('folioConsoleAasmEmailModalOpen', { bubbles: true, detail }))
}

window.Folio.Stimulus.register('f-c-aasm-email-modal', class extends window.Stimulus.Controller {
  static values = {
    title: String,
    sendEmailLabel: String
  }

  static targets = [
    'title',
    'checkbox',
    'checkboxLabel',
    'subject',
    'text',
    'submit',
    'hidden'
  ]

  static classes = ['loading']

  disconnect () {
    this.trigger = null
  }

  openFromEvent (e) {
    const { trigger, targetStateName, email, klass, id, aasmEvent, emailSubject, emailText } = e.detail

    this.trigger = trigger

    this.titleTarget.innerText = this.titleValue.replace('{STATE_NAME}', targetStateName)
    this.checkboxTarget.checked = true
    this.checkboxLabelTarget.innerText = this.sendEmailLabelValue.replace('{EMAIL}', email || '')

    this.setHidden('klass', klass)
    this.setHidden('aasm_event', aasmEvent)
    this.setHidden('id', id)
    this.setHidden('email', email)

    this.subjectTarget.value = emailSubject || ''
    this.textTarget.value = emailText || ''

    this.validate()

    window.Folio.Modal.open(this.element)

    if (this.subjectTarget.value) {
      this.textTarget.focus()
    } else {
      this.subjectTarget.focus()
    }
  }

  setHidden (key, value) {
    const input = this.hiddenTargets.find((el) => el.name === key)
    if (input) input.value = value == null ? '' : value
  }

  // Sending an empty message is never what the user meant; not sending one at
  // all is fine. When the checkbox is on, both subject and body must be present
  // — the endpoint rejects the request otherwise.
  validate () {
    const emailEnabled = this.checkboxTarget.checked
    const missingSubject = !this.subjectTarget.value.trim()
    const missingBody = !this.textTarget.value.trim()

    this.submitTarget.disabled = emailEnabled && (missingSubject || missingBody)
  }

  onFormChange () {
    this.validate()
  }

  onFormSubmit (e) {
    e.preventDefault()

    if (this.element.classList.contains(this.loadingClass)) return

    const form = e.target
    const trigger = this.trigger
    const payload = window.Folio.formToHash(form)

    this.element.classList.add(this.loadingClass)
    // Close before apiPost so Folio.Api's auto-flash lands in the layout,
    // not inside this still-open modal.
    window.Folio.Modal.close(this.element)

    window.Folio.Api.apiPost(form.action, payload).then((res) => {
      if (trigger) {
        const state = trigger.closest('.f-c-state')
        if (state && res && res.data) state.outerHTML = res.data
      }

      this.trigger = null
      form.reset()
    }).catch((error) => {
      window.Folio.Modal.open(this.element)
      document.dispatchEvent(new window.CustomEvent('folio:flash', {
        bubbles: true,
        detail: { flash: { content: error.message, variant: 'danger' } }
      }))
    }).finally(() => {
      this.element.classList.remove(this.loadingClass)
    })
  }
})
