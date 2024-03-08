window.Folio.Stimulus.register('f-c-state', class extends window.Stimulus.Controller {
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
      if (res && res.data) {
        this.element.outerHTML = res.data
      }
    }).catch(() => {
      this.element.classList.remove('f-c-state--loading')
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
