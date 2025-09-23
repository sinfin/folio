window.Folio.Stimulus.register('f-c-file-placements-multi-picker-fields-placement', class extends window.Stimulus.Controller {
  static values = {
    state: String,
    embed: { type: Boolean, default: false }
  }

  static targets = ['alt', 'description', 'pickerWrap', 'altWrap', 'embedFieldsWrap']

  connect () {
    if (this.stateValue !== 'filled') {
      const filled = this.fillFromParent()

      if (filled) {
        this.stateValue = 'filled'
      } else {
        console.error('Failed to fill from parent! Removing .f-c-file-placements-multi-picker-fields-placement')
        this.element.dispatchEvent(new CustomEvent('f-nested-fields:removeFields', { bubbles: true }))
      }
    }
  }

  disconnect () {
    if (this.highlightTimeout) {
      window.clearTimeout(this.highlightTimeout)
    }
  }

  fillFromParent () {
    const parent = this.element.closest('.f-nested-fields__fields')

    if (parent) {
      if (parent.dataset.file) {
        try {
          const fileJson = parent.dataset.file
          const file = JSON.parse(fileJson)
          this.altTarget.value = file.attributes.alt
          this.descriptionTarget.value = file.attributes.description

          const picker = this.element.querySelector('.f-c-files-picker')

          if (!picker) {
            console.error('Failed to find .f-c-files-picker element')
            return false
          }

          picker.setAttribute('data-f-c-files-picker-serialized-file-json-value', fileJson)

          return true
        } catch (error) {
          console.error('Failed to parse JSON from parent dataset', error)
        }
      } else if (parent.dataset.embed === 'true') {
        for (const disabled of this.embedFieldsWrapTarget.querySelectorAll('[disabled]')) {
          disabled.disabled = false
        }

        this.embedFieldsWrapTarget.hidden = false

        if (this.hasPickerWrapTarget) this.pickerWrapTarget.remove()
        if (this.hasAltWrapTarget) this.altWrapTarget.remove()

        this.embedValue = true

        return true
      }
    }

    return false
  }

  onNonUniqueClick (e) {
    e.preventDefault()

    const input = this.element.querySelector('.f-c-files-picker__input--file_id')
    const fileId = input.value
    const otherInputs = this.element.closest('.f-nested-fields__fields-wrap').querySelectorAll(`.f-c-files-picker__input--file_id[value="${fileId}"]`)

    for (const otherInput of otherInputs) {
      if (otherInput !== input) {
        const placement = otherInput.closest('.f-c-file-placements-multi-picker-fields-placement')

        if (placement) {
          placement.scrollIntoView({ behavior: 'smooth', block: 'center' })
          placement.dispatchEvent(new CustomEvent('f-c-file-placements-multi-picker-fields-placement:highlight'))
          break
        }
      }
    }
  }

  onHighlight (e) {
    this.element.classList.add('f-c-file-placements-multi-picker-fields-placement--highlighted')
    this.highlightTimeout = window.setTimeout(() => {
      this.element.classList.remove('f-c-file-placements-multi-picker-fields-placement--highlighted')
    }, 500)
  }
})
