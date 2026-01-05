window.Folio.Stimulus.register('f-c-ui-index-header-query-form', class extends window.Stimulus.Controller {
  static values = {
    url: String
  }

  onQueryAutocompleteSelected (e) {
    this.submit()
  }

  submit () {
    const newParams = []

    // Only add non-empty values
    for (const formControl of this.element.querySelectorAll('input, .form-control')) {
      const value = formControl.value

      if (value && value.toString().trim() !== '') {
        newParams.push([formControl.name.replace(/f-c-ui-index-header-query-form\[([^]+)\]/, '$1'), value])
      }
    }

    // Sort newParams by key to ensure consistent order
    newParams.sort((a, b) => a[0].localeCompare(b[0]))

    let urlString = this.urlValue || window.location.href
    if (urlString.indexOf('/') === 0) {
      urlString = window.location.origin + urlString
    }
    const url = new URL(urlString)
    url.search = ''

    newParams.forEach(param => {
      url.searchParams.append(param[0], param[1])
    })

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

  onInputKeypress (e) {
    if (e.key === 'Enter') {
      e.preventDefault()
      this.submit()
    }
  }
})
