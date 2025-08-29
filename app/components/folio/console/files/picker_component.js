//= require folio/capitalize

window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.Files = window.FolioConsole.Files || {}
window.FolioConsole.Files.Picker = window.FolioConsole.Files.Picker || {}

window.FolioConsole.Files.Picker.addControlsForStimulusController = (opts) => {
  ['modal', 'destroy'].forEach((key) => {
    const button = document.createElement('button')

    button.type = 'button'
    button.className = `${opts.className}__btn ${opts.className}__btn--${key}`

    if (key === 'modal') button.dataset.file = opts.element.dataset.file

    const icon = window.Folio.Ui.Icon.create(key === 'modal' ? 'edit_box' : 'close')
    button.appendChild(icon)

    button.dataset.action = `f-c-files-picker#onFormControl${window.Folio.capitalize(key)}Click`

    opts.parent.appendChild(button)
  })
}

window.Folio.Stimulus.register('f-c-files-picker', class extends window.Stimulus.Controller {
  static targets = ['idInput', 'content', 'fileIdInput', 'destroyInput', 'altValue']

  static values = {
    fileType: String,
    hasFile: Boolean,
    inReact: { type: Boolean, default: false },
    reactFile: { type: Object, default: {} }
  }

  connect () {
    if (this.reactFileValue && this.reactFileValue.attributes && this.contentTarget.childNodes.length === 0) {
      this.createFile(this.reactFileValue)
    }

    this.boundOnSelected = this.onSelected.bind(this)
    this.element.addEventListener(this.selectedEventName(), this.boundOnSelected)

    this.boundOnUpdated = this.onUpdated.bind(this)
    this.element.addEventListener(window.FolioConsole.Events.FOLIO_CONSOLE_FILE_UPDATED, this.boundOnUpdated)
  }

  disconnect () {
    this.element.removeEventListener(this.selectedEventName(), this.boundOnSelected)
    delete this.boundOnSelected
  }

  selectedEventName () {
    return `folioConsoleModalSingleSelect/${this.fileTypeValue}/selected`
  }

  clear () {
    this.updateAlt()

    if (this.inReactValue) {
      this.triggerReactFileUpdate(null)
    } else {
      this.destroyInputTarget.value = '1'
      this.destroyInputTarget.disabled = false

      this.fileIdInputTarget.value = ''

      this.hasFileValue = false
      this.contentTarget.innerHTML = ''

      this.triggerPreviewRefresh()
    }
  }

  onSelected (e) {
    if (!this.inReactValue) {
      this.destroyInputTarget.value = '0'
      this.destroyInputTarget.disabled = true

      this.fileIdInputTarget.value = e.detail.file.id
    }

    this.contentTarget.innerHTML = ''
    this.hasFileValue = true

    this.createFile(e.detail.file)
    this.updateAlt(e.detail.file)

    if (this.inReactValue) {
      this.triggerReactFileUpdate(e.detail.file)
    } else {
      this.triggerPreviewRefresh()
    }
  }

  onUpdated (e) {
    if (e.detail.file) {
      this.contentTarget.innerHTML = ''
      this.createFile(e.detail.file)
      this.updateAlt(e.detail.file)
    }
  }

  updateAlt (file) {
    if (!this.hasAltValueTarget) return
    this.altValueTarget.innerHTML = file ? (file.attributes.alt || '') : ''
  }

  triggerReactFileUpdate (file) {
    this.element.dispatchEvent(new window.CustomEvent('folioConsoleFilePickerInReact/fileUpdate', { bubbles: true, detail: { file } }))
  }

  createFile (serializedFile) {
    switch (serializedFile.attributes.human_type) {
      case 'audio':
      case 'video':
        this.createPlayer(serializedFile)
        break
      case 'image':
        this.createImage(serializedFile)
        break
      case 'document':
        this.createDocument(serializedFile)
        break
      default:
        throw new Error(`Unknown human_type ${serializedFile.attributes.human_type}`)
    }
  }

  createImage (serializedFile) {
    this.contentTarget.appendChild(window.FolioConsole.Files.Picker.Image.create(serializedFile))
  }

  createDocument (serializedFile) {
    this.contentTarget.appendChild(window.FolioConsole.Files.Picker.Document.create(serializedFile))
  }

  createPlayer (serializedFile) {
    this.contentTarget.appendChild(window.Folio.Player.create(serializedFile, { showFormControls: true }))
  }

  onBtnClick (e) {
    e.preventDefault()

    window.FolioConsole.Autosave.pause()

    const modal = document.querySelector('.f-c-files-index-modal')
    modal.dispatchEvent(new CustomEvent('f-c-files-index-modal:openWithType', { detail: { fileType: this.fileTypeValue } }))
  }

  onFormControlModalClick (e) {
    e.preventDefault()
    this.openModal({ trigger: e.currentTarget, file: JSON.parse(e.currentTarget.dataset.file) })
  }

  openModal ({ trigger, file, autoFocusField }) {
    window.FolioConsole.Autosave.pause()

    const eventName = `folioConsoleModalSingleSelect/${this.fileTypeValue}/showFileModal`
    trigger.dispatchEvent(new window.CustomEvent(eventName, { bubbles: true, detail: { file, autoFocusField } }))
  }

  onFormControlDestroyClick (e) {
    e.preventDefault()
    if (!window.confirm(window.FolioConsole.translations.removePrompt)) return
    this.clear()
  }

  triggerPreviewRefresh () {
    this.element.dispatchEvent(new window.CustomEvent('folioConsoleCustomChange', { bubbles: true }))
  }

  onAltClick (e) {
    window.FolioConsole.Autosave.pause()

    this.openModal({ trigger: e.currentTarget, file: JSON.parse(this.element.querySelector('.f-c-files-picker-thumb').dataset.file), autoFocusField: 'alt' })
  }
})
