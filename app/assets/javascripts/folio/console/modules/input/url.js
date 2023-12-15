window.Folio.Stimulus.register('f-c-input-url', class extends window.Stimulus.Controller {
  static values = {
    initializing: { type: Boolean, default: false },
    initialized: { type: Boolean, default: false }
  }

  connect () {
    this.initializeHtml()
  }

  disconnect () {
    if (this.hintTimeout) { window.clearTimeout(this.hintTimeout) }

    if (!this.initializedValue) return

    if (this.select) {
      const $select = window.jQuery(this.select)
      $select.select2('destroy')
      $select.off('select2:select')

      delete this.select
    }
  }

  initializeHtml () {
    if (this.initializingValue) {
      this.initializedValue = true
      return
    }

    this.initializingValue = true

    const row = document.createElement('div')
    row.className = 'row f-c-input-url-row'

    const selectCol = document.createElement('div')
    selectCol.className = 'col-md-4 f-c-input-url-col f-c-input-url-col--select'

    this.select = document.createElement('select')
    this.select.className = 'f-c-input-url-select form-control form-control-select form-select select'
    selectCol.appendChild(this.select)

    const inputCol = document.createElement('div')
    inputCol.className = 'col-md-8 f-c-input-url-col f-c-input-url-col--input'

    row.appendChild(selectCol)
    row.appendChild(inputCol)

    const $select = window.jQuery(this.select)

    $select.select2({
      width: '100%',
      language: document.documentElement.lang,
      ajax: {
        url: '/console/api/links',
        dataType: 'JSON',
        minimumInputLength: 0,
        cache: false,
        data: (params) => ({ q: params.term }),
        processResults: (data, params) => ({
          results: data.data.map((h) => ({
            ...h,
            id: h.url,
            text: h.label
          }))
        })
      }
    })

    $select.on('select2:select', (e) => {
      this.element.value = e.params.data.id
      this.element.classList.add('form-control--hinted')
      this.element.focus()

      this.hintTimeout = window.setTimeout(() => {
        this.element.classList.remove('form-control--hinted')
      }, 300)
    })

    this.element.parentNode.insertBefore(row, this.element)
    inputCol.appendChild(this.element)
  }
})
