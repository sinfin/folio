window.Folio.Stimulus.register('f-c-files-show-modal', class extends window.Stimulus.Controller {
  static values = {
    id: { type: String, default: '' }
  }

  idValueChanged (to, from) {
    if (to === from) return

    if (to) {
      window.Folio.Modal.open(this.element)
    } else {
      window.Folio.Modal.close(this.element)
    }
  }

  onModalClosed () {
    this.idValue = ''
    this.element.querySelector('turbo-frame').src = ''
    this.element.querySelector('turbo-frame').innerHTML = ''
  }

  openWithUrl (e) {
    if (!e || !e.detail) return
    this.showFile({ id: e.detail.id, url: e.detail.url })
  }

  showFile ({ id, url }) {
    if (!id || !url) return

    this.idValue = id
    window.Turbo.visit(url, { frame: this.element.querySelector('turbo-frame').id })
  }

  onFileDeleted (e) {
    this.idValue = ''
  }
})
