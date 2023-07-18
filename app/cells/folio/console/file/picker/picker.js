//= require folio/capitalize

window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.File = window.FolioConsole.File || {}
window.FolioConsole.File.Picker = window.FolioConsole.File.Picker || {}

window.FolioConsole.File.Picker.addControlsForStimulusController = (opts) => {
  ['modal', 'destroy'].forEach((key) => {
    const button = document.createElement('button')

    button.type = 'button'
    button.className = `${opts.className}__btn ${opts.className}__btn--${key}`

    if (key === 'modal') button.dataset.file = opts.element.dataset.file

    const icon = window.Folio.Ui.Icon.create(key === 'modal' ? 'edit_box' : 'close')
    button.appendChild(icon)

    button.dataset.action = `f-c-file-picker#onFormControl${window.Folio.capitalize(key)}Click`

    opts.parent.appendChild(button)
  })
}

window.Folio.Stimulus.register('f-c-file-picker', class extends window.Stimulus.Controller {
  static targets = ['idInput', 'content', 'fileIdInput', 'destroyInput']

  static values = {
    fileType: String,
    hasFile: Boolean,
    inReact: { type: Boolean, default: false },
    reactFile: { type: Object, default: {} },
  }

  connect () {
    if (this.reactFileValue && this.reactFileValue.attributes && this.contentTarget.childNodes.length === 0) {
      this.createFile(this.reactFileValue)
    }

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

    if (this.inReactValue) {
      this.triggerReactFileUpdate(e.detail.file)
    } else {
      this.triggerPreviewRefresh()
    }
  }

  triggerReactFileUpdate (file) {
    this.element.dispatchEvent(new window.CustomEvent(`folioConsoleFilePickerInReact/fileUpdate`, { bubbles: true, detail: { file } }))
  }

  createFile (serializedFile) {
    switch (serializedFile.attributes.human_type) {
      case 'audio':
      case 'video':
        this.createPlayer(serializedFile)
        break
      case 'image':
        this.createThumbnail(serializedFile)
        break
      case 'document':
        this.createDocument(serializedFile)
        break
      default:
        throw new Error(`Unknown human_type ${serializedFile.attributes.human_type}`)
    }
  }

  createThumbnail (serializedFile) {
    this.contentTarget.appendChild(window.FolioConsole.File.Picker.Thumb.create(serializedFile))
  }

  createDocument (serializedFile) {
    this.contentTarget.appendChild(window.FolioConsole.File.Picker.Document.create(serializedFile))
  }

  createPlayer (serializedFile) {
    this.contentTarget.appendChild(window.Folio.Player.create(serializedFile, { showFormControls: true }))
  }

  onBtnClick (e) {
    e.preventDefault()
    e.currentTarget.dispatchEvent(new window.CustomEvent(`folioConsoleModalSingleSelect/${this.fileTypeValue}/showModal`, { bubbles: true }))
  }

  onFormControlModalClick (e) {
    e.preventDefault()

    e.currentTarget.dispatchEvent(new window.CustomEvent(`folioConsoleModalSingleSelect/${this.fileTypeValue}/showFileModal`, { bubbles: true, detail: { file: JSON.parse(e.currentTarget.dataset.file) } }))
  }

  onFormControlDestroyClick (e) {
    e.preventDefault()
    if (!window.confirm(window.FolioConsole.translations.removePrompt)) return
    this.clear()
  }

  triggerPreviewRefresh () {
    this.element.dispatchEvent(new window.CustomEvent('folioConsoleCustomChange', { bubbles: true }))
  }
})
