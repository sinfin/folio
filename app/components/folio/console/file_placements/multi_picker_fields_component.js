window.Folio.Stimulus.register('f-c-file-placements-multi-picker-fields', class extends window.Stimulus.Controller {
  static targets = []

  static values = {}

  connect () {
  }

  onAddEmbedClick () {
    console.log('onAddEmbedClick')
  }

  onBatchBarAddToPicker (e) {
    const fields = this.element.querySelector('.f-nested-fields')
    if (!fields) throw new Error('f-nested-fields not found')

    const fileIds = e.detail.fileIds
    if (!fileIds || fileIds.length < 1) throw new Error('fileIds not provided')

    const attributesCollection = fileIds.map((fileId) => {
      return {
        'data-file-id': fileId
      }
    })

    fields.dispatchEvent(new CustomEvent('f-nested-fields:addMultipleWithAttributes', {
      detail: { attributesCollection }
    }))
  }
})
