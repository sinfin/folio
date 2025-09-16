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

    const files = e.detail.files
    if (!files || files.length < 1) throw new Error('files not provided')

    const attributesCollection = files.map((file) => {
      return {
        'data-file': JSON.stringify(file)
      }
    })

    fields.dispatchEvent(new CustomEvent('f-nested-fields:addMultipleWithAttributes', {
      detail: { attributesCollection }
    }))
  }
})
