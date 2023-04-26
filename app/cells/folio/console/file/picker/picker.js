window.Folio.Stimulus.register('f-c-file-picker', class extends window.Stimulus.Controller {
  static targets = ["idInput", "playerWrap"]

  static values = {
    fileType: String,
    hasFile: Boolean,
  }

  connect () {
    this.boundOnSelected = this.onSelected.bind(this)
    this.element.addEventListener(this.selectedEventName(), this.boundOnSelected)
  }

  disconnect () {
    this.element.removeEventListener(this.selectedEventName(), this.boundOnSelected)
    this.boundOnSelected = null
  }

  selectedEventName () {
    return `folioConsoleModalSingleSelect/${this.fileTypeValue}/selected`
  }

  onSelected (e) {
    this.createPlayer(e.detail.file)
  }

  createPlayer (serializedFile) {
    let existing

    while (existing = this.playerWrapTarget.querySelector('.f-player')) {
      this.playerWrapTarget.removeChild(existing)
    }

    this.hasFileValue = true
    this.playerWrapTarget.appendChild(window.Folio.Player.create(serializedFile))
  }

  onBtnClick (e) {
    e.preventDefault()
    e.target.dispatchEvent(new window.CustomEvent(`folioConsoleModalSingleSelect/${this.fileTypeValue}`, { bubbles: true }))
  }
})
