window.Folio.Stimulus.register('f-c-state', class extends window.Stimulus.Controller {
  static values = {
    reloadForm: { type: Boolean, default: false }
  }

  onTriggerClick (e) {
    e.preventDefault()

    const trigger = e.currentTarget

    if (trigger.dataset.confirmation) {
      if (!window.confirm(trigger.dataset.confirmation)) return
    }

    const modalUrl = trigger.dataset.modalUrl

    if (modalUrl) {
      return this.openModal(trigger)
    }

    const emailModal = trigger.dataset.aasmEmailModal

    if (emailModal) {
      throw new Error('not implemented')
    }

    this.element.classList.add('f-c-state--loading')

    window.Folio.Api.apiPost(trigger.dataset.url).then((res) => {
      if (this.reloadFormValue) {
        const form = this.element.closest('form')
        const formFooter = form && form.querySelector('.f-c-form-footer')

        if (formFooter) {
          formFooter.dispatchEvent(new CustomEvent('fCPageReload'))
        } else {
          window.location.reload()
        }
      }

      if (res && res.data) {
        this.element.outerHTML = res.data
      }
    }).catch((error) => {
      this.element.classList.remove('f-c-state--loading')

      // Check if error has responseData with meta.validation_box_html
      if (error.responseData && error.responseData.meta && error.responseData.meta.validation_box_html) {
        const form = this.element.closest('form')
        if (form) {
          const validationBoxes = form.querySelector('.f-c-form-header__validation-boxes')
          if (validationBoxes) {
            const existingDangerBox = validationBoxes.querySelector('.f-c-ui-validation-box--variant-danger')
            if (existingDangerBox) {
              existingDangerBox.outerHTML = error.responseData.meta.validation_box_html
            } else {
              validationBoxes.insertAdjacentHTML('afterbegin', error.responseData.meta.validation_box_html)
            }
          }
        }
      }

      window.FolioConsole.Ui.Flash.alert(error.message)
    })
  }

  openModal (trigger) {
    window.FolioConsole.FormModal.open({
      url: trigger.dataset.modalUrl,
      title: trigger.dataset.modalTitle,
      trigger
    })
  }
})
