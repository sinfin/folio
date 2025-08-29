window.Folio.Stimulus.register('f-c-ui-index-filters', class extends window.Stimulus.Controller {
  onChange () {
    this.element.requestSubmit()
  }

  onSubmit (e) {
    // Prevent the default form submission
    e.preventDefault()

    // Remove empty form fields before submission
    const formData = new FormData(this.element)
    const url = new URL(this.element.action || window.location.href)

    // Clear existing search params
    url.search = ''

    // Only add non-empty values
    for (const [key, value] of formData.entries()) {
      if (value && value.toString().trim() !== '') {
        url.searchParams.append(key, value)
      }
    }

    // Navigate to the clean URL
    const turboFrame = window.Turbo ? this.element.closest('turbo-frame') : null

    if (turboFrame) {
      // Use frame-targeted Turbo navigation to stay within the frame context
      const frameId = turboFrame.getAttribute('id')
      window.Turbo.visit(url.toString(), { frame: frameId })
    } else {
      // Use regular navigation otherwise
      window.location.href = url.toString()
    }
  }

  onToggleClick (e) {
    e.preventDefault()
    this.element.classList.toggle('f-c-ui-index-filters--expanded')
  }

  onResetInputClick (e) {
    e.preventDefault()

    const group = e.target.closest('.input-group')
    if (!group) return

    const input = group.querySelector('.form-control')
    if (!input) return

    input.value = ''
    this.element.requestSubmit()
  }
})
