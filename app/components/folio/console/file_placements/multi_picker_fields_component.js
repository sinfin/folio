window.Folio.Stimulus.register('f-c-file-placements-multi-picker-fields', class extends window.Stimulus.Controller {
  static values = {
    empty: Boolean
  }

  onAddEmbedClick () {
    const fields = this.element.querySelector('.f-nested-fields')
    if (!fields) throw new Error('f-nested-fields not found')

    const attributesCollection = [{ 'data-embed': 'true' }]

    fields.dispatchEvent(new CustomEvent('f-nested-fields:addMultipleWithAttributes', {
      detail: { attributesCollection }
    }))
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

  onCountChange () {
    const placements = this.element.querySelectorAll('.f-c-file-placements-multi-picker-fields-placement')
    const empty = placements.length === 0

    if (empty !== this.emptyValue) {
      this.emptyValue = empty
    }
  }
})
