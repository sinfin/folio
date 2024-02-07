window.Folio.Stimulus.register('f-c-private-attachments-fields', class extends window.Stimulus.Controller {
  static targets = [
    'loader',
    'addWrap',
    'template',
    'attachment',
    'attachmentsWrap',
    'addButton',
    'destroyed',
    'positionInput'
  ]

  static values = {
    fileType: String,
    fileHumanType: String,
    baseKey: String,
    single: { type: Boolean, default: false },
  }

  connect () {
    this.initFromLoaderData()
    this.addDropzone()
  }

  disconnect () {
    if (this.templateNode) {
      delete this.templateNode
    }

    if (this.dropzone) {
      window.Folio.S3Upload.destroyDropzone(this.dropzone)
      delete this.dropzone
    }
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
    input.disabled = input.type === "text" ? false : (hash.id ? false : true)
    input.name = `${this.baseKeyValue}[${hash.id}][${key}]`
    input.value = hash.attributes[key] || ""
  }

  createTemplateNodeIfNeeded () {
    if (this.templateNode) return
    const parser = new window.DOMParser()
    const html = this.templateTarget.innerHTML
    const node = parser.parseFromString(html, 'text/html').body.childNodes[0]
    node.dataset.fCPrivateAttachmentsFieldsTarget = 'attachment'

    this.templateNode = node
  }

  addDropzone () {
    this.dropzone = window.Folio.S3Upload.createDropzone({
      element: this.addButtonTarget,
      fileType: this.fileTypeValue,
      fileHumanType: this.fileHumanTypeValue,
      dropzoneOptions: { disablePreviews: true },
      onStart: (s3Path, fileAttributes) => {
        if (this.singleValue && this.keptAttachmentsCount && this.keptAttachmentsCount > 0) return

        const hash = {
          s3Path,
          id: null,
          type: "private_attachment",
          attributes: {
            id: null,
            file_size: fileAttributes.file_size,
            file_name: fileAttributes.file_name,
            title: fileAttributes.file_name,
            type: null,
            expiring_url: null,
          }
        }

        this.addAttachment(hash)
        this.afterCountUpdate()
      },
      onSuccess: (s3Path, fileFromApi) => {
        this.attachmentTargets.forEach((attachmentTarget) => {
          if (attachmentTarget.dataset.s3Path === s3Path) {
            this.updateAttachment(attachmentTarget, fileFromApi)
            const progress = attachmentTarget.querySelector('.f-c-private-attachments-fields__attachment-progress')
            progress.classList.add('f-c-private-attachments-fields__attachment-progress--fresh')
            progress.style.width = '100%'
          }
        })

        this.triggerChange()
      },
      onFailure: (s3Path) => {
        if (!s3Path) return

        this.attachmentTargets.forEach((attachmentTarget) => {
          if (attachmentTarget.dataset.s3Path === s3Path) {
            attachmentTarget.remove()
          }
        })

        this.afterCountUpdate()
      },
      onProgress: (s3Path, roundedProgress, text) => {
        this.attachmentTargets.forEach((attachmentTarget) => {
          if (attachmentTarget.dataset.s3Path === s3Path) {
            attachmentTarget
              .querySelector('.f-c-private-attachments-fields__attachment-progress')
              .style
              .width = `${roundedProgress}%`
          }
        })
      }
    })
  }

  destroyAttachment (attachment) {
    this.destroyedTarget.appendChild(attachment)

    attachment.querySelector('.f-c-private-attachments-fields__input--position').remove()

    attachment
      .querySelector('.f-c-private-attachments-fields__input--_destroy')
      .value = "1"

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
