window.Folio.Stimulus.register('f-c-file-picker', class extends window.Stimulus.Controller {
  static targets = ["idInput", "playerWrap", "fileIdInput", "destroyInput"]

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

  clear () {
    this.destroyInputTarget.value = "1"
    this.destroyInputTarget.disabled = false

    this.fileIdInputTarget.value = ""

    this.hasFileValue = false
    this.playerWrapTarget.innerHTML = ""
  }

  onSelected (e) {
    this.destroyInputTarget.value = "0"
    this.destroyInputTarget.disabled = true

    this.fileIdInputTarget.value = e.detail.file.id

    this.createPlayer(e.detail.file)
  }

  createPlayer (serializedFile) {
    let existing

    while (existing = this.playerWrapTarget.querySelector('.f-player')) {
      this.playerWrapTarget.removeChild(existing)
    }

    this.hasFileValue = true
    this.playerWrapTarget.appendChild(window.Folio.Player.create(serializedFile, { showFormControls: true }))
  }

  onBtnClick (e) {
    e.preventDefault()
    e.target.dispatchEvent(new window.CustomEvent(`folioConsoleModalSingleSelect/${this.fileTypeValue}/showModal`, { bubbles: true }))
  }

  onFormControlModalClick (e) {
    e.preventDefault()
    console.log(e)
    e.target.dispatchEvent(new window.CustomEvent(`folioConsoleModalSingleSelect/${this.fileTypeValue}/showFileModal`, { bubbles: true, detail: { file: JSON.parse(e.target.dataset.file) } }))
  }

  onFormControlDestroyClick (e) {
    e.preventDefault()
    if (!window.confirm(window.FolioConsole.translations.removePrompt)) return
    this.clear()
  }
})
