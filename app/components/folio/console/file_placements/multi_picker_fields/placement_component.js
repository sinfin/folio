window.Folio.Stimulus.register('f-c-file-placements-multi-picker-fields-placement', class extends window.Stimulus.Controller {
  static values = {
    state: String
  }

  static targets = ['alt', 'description']

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

  fillFromParent () {
    const parent = this.element.closest('.f-nested-fields__fields')

    if (parent && parent.dataset.file) {
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
    }

    return false
  }
})
