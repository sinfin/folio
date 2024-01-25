window.Folio.Stimulus.register('f-c-private-attachments-fields', class extends window.Stimulus.Controller {
  static targets = ['loader', 'addWrap', 'template', 'attachment', 'attachmentsWrap', 'addButton']

  static values = {
    fileType: String,
    fileHumanType: String,
    baseKey: String,
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

    this.loaderTarget.parentNode.removeChild(this.loaderTarget)

    hashes.forEach((hash) => { this.addAttachment(hash) })

    this.setPositions()
  }

  setPositions () {
    this.attachmentTargets.forEach((attachmentTarget, i) => {
      attachmentTarget.querySelector('.f-c-private-attachments-fields__input--position').value = i + 1
    })
  }

  addAttachment (hash) {
    this.createTemplateNodeIfNeeded()

    const attachment = this.templateNode.cloneNode(true)

    this.updateAttachment(attachment, hash)

    this.attachmentsWrapTarget.appendChild(attachment)
  }

  updateAttachment (attachment, hash) {
    const keys = ['id', '_destroy', 'title']
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
        this.setPositions()
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

        this.element.dispatchEvent(new window.Event('change', { bubbles: true }))
      },
      onFailure: (s3Path) => {
        if (!s3Path) return

        this.attachmentTargets.forEach((attachmentTarget) => {
          if (attachmentTarget.dataset.s3Path === s3Path) {
            attachmentTarget.parentNode.removeChild(attachmentTarget)
          }
        })

        this.setPositions()
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
    attachment.hidden = true
    attachment
      .querySelector('.f-c-private-attachments-fields__input--_destroy')
      .value = "1"

    this.setPositions()
  }

  onDestroyClick (e) {
    e.preventDefault()

    window.Folio.Confirm.confirm(() => {
      this.destroyAttachment(e.target.closest('.f-c-private-attachments-fields__attachment'))
    })
  }
})
