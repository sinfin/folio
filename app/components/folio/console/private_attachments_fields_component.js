window.Folio.Stimulus.register('f-c-private-attachments-fields', class extends window.Stimulus.Controller {
  static targets = [
    'loader',
    'addWrap',
    'template',
    'attachment',
    'attachmentsWrap',
    'destroyed',
    'positionInput'
  ]

  static values = {
    fileType: String,
    baseKey: String,
    single: { type: Boolean, default: false }
  }

  static ERROR_MESSAGES = {
    en: {
      failedToProcessFile: 'Failed to process file',
      failedToFinishUploading: 'Failed to finish uploading file'
    },
    cs: {
      failedToProcessFile: 'Nepodařilo se zpracovat soubor',
      failedToFinishUploading: 'Nepodařilo se dokončit nahrávání souboru'
    }
  }

  connect () {
    this.initFromLoaderData()
  }

  disconnect () {
    if (this.templateNode) {
      delete this.templateNode
    }

    this.clearS3AfterTimeouts()
  }

  initFromLoaderData () {
    if (!this.hasLoaderTarget) return

    const hashes = JSON.parse(this.loaderTarget.dataset.attachments)

    this.loaderTarget.remove()

    hashes.forEach((hash) => { this.addAttachment(hash) })

    this.afterCountUpdate()
  }

  afterCountUpdate () {
    if (this.singleValue) {
      this.keptAttachmentsCount = this.attachmentsWrapTarget.children.length
      this.addWrapTarget.hidden = this.keptAttachmentsCount > 0
    }

    this.positionInputTargets.forEach((positionInput, i) => {
      positionInput.value = i + 1
    })
  }

  addAttachment (hash) {
    this.createTemplateNodeIfNeeded()

    const attachment = this.templateNode.cloneNode(true)

    this.updateAttachment(attachment, hash)

    this.attachmentsWrapTarget.appendChild(attachment)
  }

  updateAttachment (attachment, hash) {
    const keys = ['id', '_destroy', 'title', 'position']

    keys.forEach((key) => {
      this.updateAttachmentInput(attachment, hash, key)
    })

    attachment.querySelector('.f-c-private-attachments-fields__attachment-link').href = hash.attributes.expiring_url

    if (hash.s3Path) {
      attachment.dataset.s3Path = hash.s3Path
    } else {
      delete attachment.dataset.s3Path
    }
  }

  updateAttachmentInput (attachment, hash, key) {
    const input = attachment.querySelector(`.f-c-private-attachments-fields__input--${key}`)
    input.disabled = input.type === 'text' ? false : (!hash.id)
    input.name = `${this.baseKeyValue}[${hash.id}][${key}]`
    input.value = hash.attributes[key] || ''
  }

  createTemplateNodeIfNeeded () {
    if (this.templateNode) return
    const parser = new window.DOMParser()
    const html = this.templateTarget.innerHTML
    const node = parser.parseFromString(html, 'text/html').body.childNodes[0]
    node.dataset.fCPrivateAttachmentsFieldsTarget = 'attachment'

    this.templateNode = node
  }

  onUppyUploadStart (event) {
    const { file } = event.detail

    if (!file || !file.s3_path) return
    if (this.singleValue && this.keptAttachmentsCount && this.keptAttachmentsCount > 0) return

    const hash = {
      s3Path: file.s3_path,
      id: null,
      type: 'private_attachment',
      attributes: {
        id: null,
        file_size: file.size,
        file_name: file.name,
        title: file.name,
        type: null,
        expiring_url: null
      }
    }

    this.addAttachment(hash)
    this.afterCountUpdate()
  }

  onUppyUploadSuccess (event) {
    const { file } = event.detail

    if (!file || !file.s3_path) return
    if (!this.findAttachmentByS3Path(file.s3_path)) return

    this.pingS3After(file)
  }

  onUppyUploadError (event) {
    const { error, file } = event.detail
    const message = error && error.message ? error.message : window.Folio.i18n(this.constructor.ERROR_MESSAGES, 'failedToProcessFile')

    this.removePendingAttachment(file && file.s3_path)
    this.errorFlashMessage(message)
  }

  onMessage (event) {
    const message = event.detail && event.detail.message

    if (!message || message.type !== 'Folio::S3::CreateFileJob') return
    if (!message.data || message.data.file_type !== this.fileTypeValue) return

    switch (message.data.type) {
      case 'success':
        this.messageBusSuccess(message.data)
        break
      case 'failure':
        this.messageBusFailure(message.data)
        break
    }
  }

  pingS3After (file) {
    const data = {
      jwt: file.jwt,
      s3_path: file.s3_path,
      type: this.fileTypeValue,
      message_bus_client_id: window.MessageBus.clientId
    }

    window.Folio.Api.apiPost('/folio/api/s3/after', data).catch((error) => {
      this.s3AfterCatchCounters = this.s3AfterCatchCounters || {}
      this.s3AfterCatchCounters[file.s3_path] = this.s3AfterCatchCounters[file.s3_path] || 0
      this.s3AfterCatchCounters[file.s3_path] += 1

      if (this.s3AfterCatchCounters[file.s3_path] > 10) {
        this.clearS3AfterState(file.s3_path)
        this.removePendingAttachment(file.s3_path)
        this.errorFlashMessage(`${window.Folio.i18n(this.constructor.ERROR_MESSAGES, 'failedToProcessFile')}: ${error.message}`)
        return
      }

      this.s3AfterTimeouts = this.s3AfterTimeouts || {}
      if (this.s3AfterTimeouts[file.s3_path]) window.clearTimeout(this.s3AfterTimeouts[file.s3_path])

      this.s3AfterTimeouts[file.s3_path] = window.setTimeout(() => {
        this.pingS3After(file)
      }, this.s3AfterCatchCounters[file.s3_path] * 500)
    })
  }

  messageBusSuccess (data) {
    const attachment = this.findAttachmentByS3Path(data.s3_path)

    if (!attachment) return

    this.updateAttachment(attachment, data.file)
    attachment.classList.add('f-c-private-attachments-fields__attachment--fresh')
    this.clearS3AfterState(data.s3_path)
    this.triggerChange()
  }

  messageBusFailure (data) {
    const message = window.Folio.i18n(this.constructor.ERROR_MESSAGES, 'failedToFinishUploading')
    const errors = data.errors && data.errors.length ? data.errors.join(', ') : null

    this.removePendingAttachment(data.s3_path)
    this.clearS3AfterState(data.s3_path)
    this.errorFlashMessage(errors ? `${message}: ${errors}` : message)
  }

  findAttachmentByS3Path (s3Path) {
    if (!s3Path) return null

    return this.attachmentTargets.find((attachmentTarget) => attachmentTarget.dataset.s3Path === s3Path)
  }

  removePendingAttachment (s3Path) {
    const attachment = this.findAttachmentByS3Path(s3Path)

    if (!attachment) return

    attachment.remove()
    this.afterCountUpdate()
  }

  clearS3AfterState (s3Path) {
    if (!s3Path) return

    if (this.s3AfterTimeouts && this.s3AfterTimeouts[s3Path]) {
      window.clearTimeout(this.s3AfterTimeouts[s3Path])
      delete this.s3AfterTimeouts[s3Path]
    }

    if (this.s3AfterCatchCounters && this.s3AfterCatchCounters[s3Path]) {
      delete this.s3AfterCatchCounters[s3Path]
    }
  }

  clearS3AfterTimeouts () {
    if (this.s3AfterTimeouts) {
      Object.keys(this.s3AfterTimeouts).forEach((s3Path) => {
        window.clearTimeout(this.s3AfterTimeouts[s3Path])
      })

      delete this.s3AfterTimeouts
    }

    if (!this.s3AfterCatchCounters) return
    delete this.s3AfterCatchCounters
  }

  errorFlashMessage (content) {
    this.element.dispatchEvent(new CustomEvent('folio:flash', {
      bubbles: true,
      detail: {
        flash: {
          content,
          variant: 'danger'
        }
      }
    }))
  }

  destroyAttachment (attachment) {
    this.destroyedTarget.appendChild(attachment)

    attachment.querySelector('.f-c-private-attachments-fields__input--position').remove()

    attachment
      .querySelector('.f-c-private-attachments-fields__input--_destroy')
      .value = '1'

    this.afterCountUpdate()
    this.triggerChange()
  }

  onDestroyClick (e) {
    e.preventDefault()

    window.Folio.Confirm.confirm(() => {
      this.destroyAttachment(e.target.closest('.f-c-private-attachments-fields__attachment'))
    })
  }

  onArrowDownClick (e) {
    this.onArrowClick(e, false)
  }

  onArrowUpClick (e) {
    this.onArrowClick(e, true)
  }

  triggerChange () {
    this.element.dispatchEvent(new window.Event('change', { bubbles: true }))
    this.dispatch('change')
  }

  onArrowClick (e, up) {
    e.preventDefault()

    const attachment = e.target.closest('.f-c-private-attachments-fields__attachment')
    let target, position

    if (up) {
      target = attachment.previousElementSibling
      position = 'beforebegin'
    } else {
      target = attachment.nextElementSibling
      position = 'afterend'
    }

    if (target) {
      target.insertAdjacentElement(position, attachment)
      this.afterCountUpdate()
      this.triggerChange()
    }
  }
})

if (window.Folio && window.Folio.MessageBus && window.Folio.MessageBus.callbacks) {
  window.Folio.MessageBus.callbacks['f-c-private-attachments-fields'] = (message) => {
    if (!message || message.type !== 'Folio::S3::CreateFileJob') return
    if (!message.data || !message.data.file_type) return

    const selector = `.f-c-private-attachments-fields[data-f-c-private-attachments-fields-file-type-value="${message.data.file_type}"]`
    const targets = document.querySelectorAll(selector)

    for (const target of targets) {
      target.dispatchEvent(new CustomEvent('f-c-private-attachments-fields/message', { detail: { message } }))
    }
  }
}
