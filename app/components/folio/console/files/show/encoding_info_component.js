window.Folio.Stimulus.register('f-c-files-show-encoding-info', class extends window.Stimulus.Controller {
  static values = {
    fileId: Number
  }

  connect () {
    this.messageBusCallbackKey = `f-c-files-show-encoding-info--${this.fileIdValue}`
    window.Folio.MessageBus.callbacks[this.messageBusCallbackKey] = (message) => {
      if (message.type === 'Folio::CraMediaCloud::CheckProgressJob/encoding_progress' &&
          message.data.id === this.fileIdValue) {
        this.update(message.data)
      }
    }
  }

  disconnect () {
    if (this.messageBusCallbackKey && window.Folio.MessageBus.callbacks) {
      delete window.Folio.MessageBus.callbacks[this.messageBusCallbackKey]
    }
  }

  update (data) {
    const phaseEl = this.element.querySelector('.f-c-files-show-encoding-info__phase')
    const progressEl = this.element.querySelector('.f-c-files-show-encoding-info__progress')

    if (data.aasm_state === 'processing_failed') {
      if (phaseEl) {
        phaseEl.classList.add('f-c-files-show-encoding-info__phase--failed')
        phaseEl.textContent = data.failed_label || ''
      }
      if (progressEl) {
        progressEl.textContent = ''
      }
      return
    }

    if (phaseEl && data.current_phase_label) {
      phaseEl.classList.remove('f-c-files-show-encoding-info__phase--failed')
      phaseEl.textContent = data.current_phase_label
    }

    if (progressEl) {
      progressEl.textContent = data.progress_percentage != null ? `${data.progress_percentage}%` : ''
    }
  }
})
