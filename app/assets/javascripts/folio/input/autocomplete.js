//= require floating-ui-core
//= require floating-ui-dom

//= require folio/add_params_to_url
//= require folio/api
//= require folio/parameterize

window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.Autocomplete = {}

window.Folio.Input.Autocomplete.TEMPLATE_HTML = window.Folio.Input.Autocomplete.TEMPLATE_HTML || `
  <div class="f-input-autocomplete-dropdown" style="position: absolute; z-index: 2000;">
    <ul class="f-input-autocomplete-dropdown__menu dropdown-menu show" role="tooltip" style="position: static;">
    </ul>
  </div>
`

if (!window.Folio.Input.Autocomplete.TEMPLATE) {
  window.Folio.Input.Autocomplete.TEMPLATE = document.createElement('template')
  window.Folio.Input.Autocomplete.TEMPLATE.innerHTML = window.Folio.Input.Autocomplete.TEMPLATE_HTML
}

window.Folio.Stimulus.register('f-input-autocomplete', class extends window.Stimulus.Controller {
  static values = {
    url: { type: String, default: '' },
    collection: { type: String, default: '' },
    hasActiveDropdown: { type: Boolean, default: false }
  }

  connect () {
    this.element.autocomplete = 'off'

    if (this.collectionValue) {
      try {
        this.parsedItems = JSON.parse(this.collectionValue).map((item) => (
          window.Folio.parameterize(item.toLowerCase())
        ))
      } catch (e) {
        console.error('f-input-autocomplete collectionValue parse error', e)
      }
    }

    this.boundOnInput = this.onInput.bind(this)
    this.element.addEventListener('input', this.boundOnInput)

    this.preventEnterSubmit = (e) => {
      if (e.key === 'Enter' && this.hasActiveDropdownValue) {
        const active = this.autocompleteDropdown?.querySelector('.active')
        if (active) {
          e.preventDefault()
          e.stopImmediatePropagation()
        }
      }
    }
    this.element.addEventListener('keydown', this.preventEnterSubmit)
    this.element.addEventListener('keypress', this.preventEnterSubmit)

    this.boundOnKeyup = this.onKeyup.bind(this)
    this.element.addEventListener('keyup', this.boundOnKeyup)

    this.boundOnFocus = this.onFocus.bind(this)
    this.element.addEventListener('focus', this.boundOnFocus)

    this.boundOnCancel = () => { this.removeDropdown() }
    this.element.addEventListener('f-c-ui-ajax-input:success', this.boundOnCancel)
    this.element.addEventListener('f-c-ui-ajax-input:cancel', this.boundOnCancel)
  }

  disconnect () {
    this.abort()

    if (this.lastApiResults) delete this.lastApiResults
    if (this.debouncedApiLoad) delete this.debouncedApiLoad
    if (this.parsedItems) delete this.parsedItems

    if (this.boundOnKeyup) {
      this.element.removeEventListener('keyup', this.boundOnKeyup)
      delete this.boundOnKeyup
    }

    if (this.boundOnInput) {
      this.element.removeEventListener('input', this.boundOnInput)
      delete this.boundOnInput
    }

    if (this.boundOnFocus) {
      this.element.removeEventListener('focus', this.boundOnFocus)
      delete this.boundOnFocus
    }

    if (this.boundOnCancel) {
      this.element.removeEventListener('f-c-ui-ajax-input:success', this.boundOnCancel)
      this.element.removeEventListener('f-c-ui-ajax-input:cancel', this.boundOnCancel)
      delete this.boundOnCancel
    }

    if (this.preventEnterSubmit) {
      this.element.removeEventListener('keydown', this.preventEnterSubmit)
      this.element.removeEventListener('keypress', this.preventEnterSubmit)
      delete this.preventEnterSubmit
    }

    this.removeDropdown()
  }

  onKeyup (e) {
    if (!this.hasActiveDropdownValue) return

    switch (e.code) {
      case 'ArrowDown':
        e.preventDefault()
        this.handleAutocompleteActive('next')
        break
      case 'ArrowUp':
        e.preventDefault()
        this.handleAutocompleteActive('previous')
        break
      case 'Tab':
        e.preventDefault()
        if (e.shiftKey) {
          this.handleAutocompleteActive('previous')
        } else {
          this.handleAutocompleteActive('next')
        }
        break
      case 'Escape':
        this.removeDropdown()
        break
      case 'Enter': {
        const active = this.autocompleteDropdown?.querySelector('.active')
        if (active) {
          e.preventDefault()
          this.handleAutocompleteActive('select')
        } else {
          // No item selected - close dropdown and let Enter propagate to save the input value
          this.removeDropdown()
        }
        break
      }
    }
  }

  setValue (value) {
    this.element.value = value
    this.dispatch('selected')
    this.element.dispatchEvent(new Event('change'))
    this.removeDropdown()
  }

  handleAutocompleteActive (action) {
    if (!this.hasActiveDropdownValue) return

    const menu = this.autocompleteDropdown.querySelector('.f-input-autocomplete-dropdown__menu')
    const active = menu.querySelector('.active')
    let targetLi

    if (active) {
      if (action === 'previous') {
        targetLi = active.parentNode.previousElementSibling
        if (!targetLi) targetLi = menu.children[menu.children.length - 1]
      } else if (action === 'next') {
        targetLi = active.parentNode.nextElementSibling
        if (!targetLi) targetLi = menu.children[0]
      } else if (action === 'select') {
        return this.setValue(active.innerText)
      }
    } else {
      if (action === 'previous') {
        targetLi = menu.children[menu.children.length - 1]
      } else if (action === 'next') {
        targetLi = menu.children[0]
      }
    }

    if (active) {
      active.classList.remove('active')
    }

    if (targetLi) {
      targetLi.querySelector('.dropdown-item').classList.add('active')
    }
  }

  onInput (e) {
    this.loadOrSetItems(this.element.value)
  }

  onFocus (_e) {
    this.loadOrSetItems(this.element.value)
  }

  abort () {
    if (this.abortController) {
      this.abortController.abort('abort')
      delete this.abortController
    }
  }

  loadOrSetItems (rawValue) {
    const value = window.Folio.parameterize((rawValue || '').trim().toLowerCase())

    if (this.parsedItems) {
      const matcher = window.Folio.parameterize(value)
      let items = value ? this.parsedItems.filter((item) => item.includes(matcher)) : this.parsedItems.slice(0, 10)

      if (items.length === 1 && items[0] === matcher) {
        items = []
      }

      return this.setAutocompleteItems(items)
    }

    if (this.urlValue) {
      if (this.lastApiResults && this.lastApiResults[value]) {
        return this.setAutocompleteItems(this.lastApiResults[value])
      }

      if (!this.debouncedApiLoad) {
        this.debouncedApiLoad = window.Folio.debounce(this.apiLoad.bind(this))
      }

      this.debouncedApiLoad(value)
    }
  }

  apiLoad (value) {
    this.abort()
    this.abortController = new AbortController()

    const url = value ? window.Folio.addParamsToUrl(this.urlValue, { q: value }) : this.urlValue

    window.Folio.Api.apiGet(url, null, this.abortController.signal).then((res) => {
      if (res && res.data) {
        this.lastApiResults = { [value]: res.data }
        this.setAutocompleteItems(res.data)
      } else {
        this.removeDropdown()
      }
    }).catch(() => { this.removeDropdown() })
  }

  onDocumentClick (e) {
    const validTarget = e.target.closest('.f-input-autocomplete-dropdown .dropdown-item')

    if (validTarget && validTarget.closest('.f-input-autocomplete-dropdown') === this.autocompleteDropdown) {
      this.setValue(e.target.innerText)
    } else if (this.hasActiveDropdownValue) {
      if (e.target !== this.element) {
        const closest = e.target.closest('.f-c-ui-in-place-input')

        if (!closest || closest !== this.element.closest('.f-c-ui-in-place-input')) {
          this.removeDropdown()
        }
      }
    }
  }

  addDropdown (html) {
    if (!this.hasActiveDropdownValue) {
      this.autocompleteDropdown = document.importNode(window.Folio.Input.Autocomplete.TEMPLATE.content.children[0], true)
      this.autocompleteDropdown.style.width = `${this.element.offsetWidth}px`

      document.body.appendChild(this.autocompleteDropdown)

      this.floatingUiCleanup = window.FloatingUIDOM.autoUpdate(
        this.element,
        this.autocompleteDropdown,
        () => {
          const options = {
            middleware: [
              window.FloatingUIDOM.offset({ mainAxis: 8 })
            ],
            placement: 'bottom'
          }

          window.FloatingUIDOM.computePosition(this.element, this.autocompleteDropdown, options).then(({
            x,
            y,
            middlewareData,
            placement
          }) => {
            Object.assign(this.autocompleteDropdown.style, {
              left: `${x}px`,
              top: `${y}px`,
              width: `${this.element.offsetWidth}px`
            })

            this.autocompleteDropdown.setAttribute('data-popper-placement', 'bottom')
            this.autocompleteDropdown.classList.add('d-block')
          })
        }
      )

      this.boundDocumentClick = this.onDocumentClick.bind(this)
      document.addEventListener('click', this.boundDocumentClick)

      this.hasActiveDropdownValue = true
    }

    this.autocompleteDropdown.querySelector('.f-input-autocomplete-dropdown__menu').innerHTML = html
  }

  removeDropdown () {
    if (this.floatingUiCleanup) {
      this.floatingUiCleanup()
      delete this.floatingUiCleanup
    }

    if (this.boundDocumentClick) {
      document.removeEventListener('click', this.boundDocumentClick)
      delete this.boundDocumentClick
    }

    if (this.autocompleteDropdown) {
      this.autocompleteDropdown.remove()
      delete this.autocompleteDropdown
    }

    if (this.hasActiveDropdownValue) {
      this.hasActiveDropdownValue = false
    }
  }

  setAutocompleteItems (items) {
    if (items.length) {
      let html = ''

      items.forEach((item, index) => {
        if (index > 9) return
        html += `<li><span class="dropdown-item" style="cursor: pointer; overflow-wrap: break-word; white-space: normal;">${item}</span></li>`
      })

      this.addDropdown(html)
    } else {
      this.removeDropdown()
    }
  }

  hasActiveDropdownValueChanged (to, from) {
    if (to && typeof from !== 'undefined' && to !== from) {
      this.element.dispatchEvent(new Event('f-input-autocomplete:active-dropdown-changed', { bubbles: true, detail: { hasActiveDropdown: to } }))
    }
  }
})
