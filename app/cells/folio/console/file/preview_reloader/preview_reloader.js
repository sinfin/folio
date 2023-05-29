window.Folio.Stimulus.register('f-c-file-preview-reloader', class extends window.Stimulus.Controller {
  static values = { fileId: Number }

  connect () {
    window.Folio.MessageBus.callbacks[`f-c-file-preview-reloader--${this.fileIdValue}`] = (data) => {
      if (!data || data.type !== 'Folio::ApplicationJob/file_update') return
      if (Number(data.data.id) != this.fileIdValue) return
      window.top.postMessage({ type: 'refreshPreview' }, window.origin)
    }
  }

  disconnect () {
    delete window.Folio.MessageBus.callbacks[`f-c-file-preview-reloader--${this.fileIdValue}`]
  }
})
