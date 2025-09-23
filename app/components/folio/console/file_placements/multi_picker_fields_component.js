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

  onAddToPicker (e) {
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

  onCountChange (e) {
    const empty = e && e.detail && e.detail.count === 0

    if (empty !== this.emptyValue) {
      this.emptyValue = empty
    }

    // setTimeout to ensure DOM is updated first
    window.setTimeout(() => {
      this.handleDuplicates()
    }, 0)
  }

  handleDuplicates () {
    const placementsHash = {}

    for (const placement of this.element.querySelectorAll('.f-c-file-placements-multi-picker-fields-placement[data-f-c-file-placements-multi-picker-fields-placement-state-value="filled"]')) {
      const destroyInput = placement.closest('.f-nested-fields__fields').querySelector('.f-nested-fields__destroy-input')

      if (destroyInput.value !== '1') {
        const fileIdInput = placement.querySelector('.f-c-files-picker__input--file_id')

        if (fileIdInput.value) {
          placementsHash[fileIdInput.value] = placementsHash[fileIdInput.value] || []
          placementsHash[fileIdInput.value].push(placement)
        }
      }
    }

    Object.values(placementsHash).forEach((placements) => {
      placements.forEach((placement) => {
        placement.classList.toggle('f-c-file-placements-multi-picker-fields-placement--non-unique-file-id', placements.length > 1)
      })
    })
  }
})
