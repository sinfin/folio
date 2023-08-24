//= require folio/add_params_to_url

window.Dummy = window.Dummy || {}
window.Dummy.Ui = window.Dummy.Ui || {}

window.Dummy.Ui.HeaderSearch = {}

window.Dummy.Ui.HeaderSearch.i18n = {
  cs: {
    error: 'Výsledky se nepodařilo načíst.'
  },
  en: {
    error: 'Failed to load results.'
  }
}

window.Folio.Stimulus.register('d-ui-header-search', class extends window.Stimulus.Controller {
  static targets = ['mq', 'input', 'form', 'autocompleteResults']

  static values = {
    open: { type: Boolean, default: false },
    autocomplete: { type: Boolean, default: false },
    autocompleteUrl: String
  }

  connect () {
    this.debouncedOnInput = Folio.debounce(this.onInput)
  }

  disconnect () {
    if (this.abortController) {
      this.abortController.abort()
      delete this.abortController
    }

    delete this.debouncedOnInput
  }

  aClick (e) {
    const isMobile = window.Folio.isVisible(this.mqTarget)
    if (isMobile) return

    e.preventDefault()

    if (this.openValue) {
      this.formTarget.submit()
      return
    }

    this.open()
  }

  open () {
    this.openValue = true
    this.inputTarget.focus()
  }

  close () {
    if (this.openValue) {
      this.openValue = false
    }
  }

  onInput (e) {
    const value = (e.target.value || '').replace(/^\s+/, '').replace(/\s+$/, '')

    if (value) {
      this.autocompleteResultsTarget.innerHTML = ''
      this.autocompleteValue = true

      const url = window.Folio.addParamsToUrl(this.autocompleteUrlValue, { q: value })

      if (this.abortController) {
        this.abortController.abort()
      }

      this.abortController = new AbortController()

      window.Folio.Api.apiGet(url, null, this.abortController.signal)
        .then((res) => {
          if (res && res.data) {
            this.autocompleteResultsTarget.innerHTML = res.data
          } else {
            throw 'Missing search results data'
          }
        })
        .catch((error) => {
          if (error.name === 'AbortError') {
            this.autocompleteResultsTarget.innerHTML = ''
          } else {
            this.autocompleteResultsTarget.innerHTML = `<div class="d-searches-autocomplete small"><div class="d-searches-autocomplete__no-results">${Folio.i18n(window.Dummy.Ui.HeaderSearch.i18n, 'error')}</div></div>`
          }
        })
    } else {
      this.autocompleteValue = false
    }
  }

  onInputBlur (e) {
    window.setTimeout(() => {
      this.close()
    }, 300)

  }

  overlayClick (e) {
    e.preventDefault()
    this.close()
  }

  onKeydown (e) {
    if (!this.autocompleteValue) return

    if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
      const records = this.element.querySelectorAll('.d-searches-autocomplete__record')
      let focused = null
      let target

      for (let i = 0; i < records.length; i++) {
        if (records[i].classList.contains('d-searches-autocomplete__record--focused')) {
          focused = i
          records[i].classList.remove('d-searches-autocomplete__record--focused')
          break
        }
      }

      if (focused === null) {
        target = e.key === 'ArrowDown' ? 0 : (records.length - 1)
      } else {
        const shift = e.key === 'ArrowDown' ? 1 : -1
        target = focused + shift

        if (target < -1) {
          target = records.length - 1
        } else if (target > records.length - 1) {
          target = 0
        }
      }

      records[target].classList.add('d-searches-autocomplete__record--focused')
    } else if (e.key === 'Enter') {
      const focused = this.element.querySelector('.d-searches-autocomplete__record--focused')

      if (focused) {
        e.preventDefault()
        e.stopPropagation()
        focused.click()
      }
    } else if (e.key === 'Escape') {
      e.target.blur()
      this.close()
    }
  }
})
