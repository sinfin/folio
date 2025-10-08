window.Folio.Stimulus.register('f-c-files-show-thumbnails-crop-edit', class extends window.Stimulus.Controller {
  static values = {
    state: Boolean
  }

  startEditing () {
    this.stateValue = 'editing'
  }

  saveEditing () {
    this.stateValue = 'saving'
  }

  cancelEditing () {
    this.stateValue = 'viewing'
  }
})
