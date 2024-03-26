window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.Ui = window.FolioConsole.Ui || {}
window.FolioConsole.Ui.NotificationModal = window.FolioConsole.Ui.Button || {}

window.FolioConsole.Ui.NotificationModal.i18n = {
  cs: {
    close: 'Zavřít upozornění',
    submit: 'Uložit změny',
  },
  en: {
    close: 'Close notification',
    submit: 'Save changes',
  }
}

window.FolioConsole.Ui.NotificationModal.open = ({ data, trigger, onCancel }) => {
  const name = 'f-c-ui-notification-modal'
  const modal = document.querySelector(`.${name}`)
  const ctrl = window.Folio.Stimulus.APPLICATION.getControllerForElementAndIdentifier(modal, name)

  ctrl.open({ data, trigger, onCancel })
}

window.Folio.Stimulus.register('f-c-ui-notification-modal-trigger', class extends window.Stimulus.Controller {
  static values = {
    data: Object
  }

  onClick (e) {
    e.preventDefault()

    window.FolioConsole.Ui.NotificationModal.open({ data: this.dataValue, trigger: this.element })
  }
})

window.Folio.Stimulus.register('f-c-ui-notification-modal', class extends window.Stimulus.Controller {
  connect () {
    this.originalInnerHTML = this.element.innerHTML
    this.submitted = null
  }

  disconnect () {
    this.element.removeEventListener('hide.bs.modal', this.onBsModalHide)
    this.bsModal.dispose()
    delete this.bsModal
    delete this.trigger
    delete this.onCancel
  }

  submit (e) {
    e.preventDefault()
    const form = this.trigger.closest('form')

    form.requestSubmit()
    this.submitted = true

    if (this.closeOnSubmit) {
      window.Folio.Modal.close(this.element)
    }
  }

  open ({ data, trigger, onCancel }) {
    const html = this.originalInnerHTML

    this.trigger = trigger

    this.element.innerHTML = html

    const title = this.element.querySelector('.modal-title')
    const body = this.element.querySelector('.modal-body')
    const footer = this.element.querySelector('.modal-footer')

    if (data.title) {
      title.innerHTML = data.title
    } else {
      title.parentNode.removeChild(title)
    }

    if (data.body) {
      body.innerHTML = data.body
    } else {
      body.parentNode.removeChild(body)
    }

    this.onCancel = onCancel

    if (data.cancel || data.submit) {
      const buttonsData = []

      if (data.cancel) {
        buttonsData.push({
          variant: 'tertiary',
          label: typeof data.cancel === "string" ? data.cancel : window.Folio.i18n(window.FolioConsole.Ui.NotificationModal.i18n, 'close'),
          data: { controller: 'f-modal-close', action: 'f-modal-close#click' }
        })
      }

      if (data.submit) {
        buttonsData.push({
          variant: 'primary',
          label: typeof data.submit === "string" ? data.submit : window.Folio.i18n(window.FolioConsole.Ui.NotificationModal.i18n, 'submit'),
          data: { action: 'f-c-ui-notification-modal#submit' }
        })

        if (data.closeOnSubmit) {
          this.closeOnSubmit = data.closeOnSubmit
        }
      }

      footer.innerHTML = ''
      footer.appendChild(window.FolioConsole.Ui.Buttons.create(buttonsData))
    } else {
      footer.parentNode.removeChild(footer)
    }

    window.Folio.Modal.open(this.element)
  }

  onModalClose = () => {
    if (!this.submitted && this.onCancel) {
      this.onCancel()
      delete this.onCancel
    }
  }
})
