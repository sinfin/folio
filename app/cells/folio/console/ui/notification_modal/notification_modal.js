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

window.Folio.Stimulus.register('f-c-ui-notification-modal-trigger', class extends window.Stimulus.Controller {
  static values = {
    data: Object
  }

  onClick (e) {
    e.preventDefault()

    this.dispatch('trigger', {
      detail: { modal: this.dataValue, trigger: this.element },
      target: document.querySelector('.f-c-ui-notification-modal')
    })
  }
})

window.Folio.Stimulus.register('f-c-ui-notification-modal', class extends window.Stimulus.Controller {
  connect () {
    this.originalInnerHTML = this.element.innerHTML
    this.bsModal = new window.bootstrap.Modal(this.element)
  }

  disconnect () {
    this.bsModal.dispose()
    delete this.bsModal
    delete this.trigger
  }

  submit (e) {
    e.preventDefault()
    this.trigger.closest('form').submit()
  }

  onTrigger (e) {
    const html = this.originalInnerHTML

    this.trigger = e.detail.trigger

    this.element.innerHTML = html

    const title = this.element.querySelector('.modal-title')
    const body = this.element.querySelector('.modal-body')
    const footer = this.element.querySelector('.modal-footer')

    if (e.detail.modal.title) {
      title.innerHTML = e.detail.modal.title
    } else {
      title.parentNode.removeChild(title)
    }

    if (e.detail.modal.body) {
      body.innerHTML = e.detail.modal.body
    } else {
      body.parentNode.removeChild(body)
    }

    if (e.detail.modal.cancel || e.detail.modal.submit) {
      const buttonsData = []

      if (e.detail.modal.cancel) {
        buttonsData.push({
          variant: 'tertiary',
          label: window.Folio.i18n(window.FolioConsole.Ui.NotificationModal.i18n, 'close'),
          data: { bsDismiss: 'modal' }
        })
      }

      if (e.detail.modal.submit) {
        buttonsData.push({
          variant: 'primary',
          label: window.Folio.i18n(window.FolioConsole.Ui.NotificationModal.i18n, 'submit'),
          data: { action: 'f-c-ui-notification-modal#submit' }
        })
      }

      footer.innerHTML = ''
      footer.appendChild(window.FolioConsole.Ui.Buttons.create(buttonsData))
    } else {
      footer.parentNode.removeChild(footer)
    }

    this.bsModal.show()
  }
})
