window.Folio.Stimulus.register('f-c-private-attachments-fields', class extends window.Stimulus.Controller {
  static targets = ['loader', 'addWrap', 'template', 'attachment', 'attachmentsWrap']

  connect () {
    this.initFromLoaderData()
  }

  disconnect () {
    if (this.templateNode) delete this.templateNode
  }

  initFromLoaderData () {
    if (!this.hasLoaderTarget) return

    const hashes = JSON.parse(this.loaderTarget.dataset.attachments)

    this.loaderTarget.parentNode.removeChild(this.loaderTarget)

    hashes.forEach((hash) => { this.addAttachment(hash) })
  }

  addAttachment (hash) {
    this.createTemplateNodeIfNeeded()

    const attachment = this.templateNode.cloneNode(true)

    const keys = ['id', '_destroy', 'title']
    keys.forEach((key) => {
      this.updateInput(attachment, hash, key)
    })

    attachment.querySelector('.f-c-private-attachments-fields__attachment-link').href = hash.attributes.expiring_url

    this.attachmentsWrapTarget.appendChild(attachment)
  }

  updateInput (attachment, hash, key) {
    const input = attachment.querySelector(`.f-c-private-attachments-fields__input--${key}`)
    input.name = `[${hash.id}][${key}]`
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
})
