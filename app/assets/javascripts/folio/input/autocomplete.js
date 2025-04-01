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
    dropdownHover: { type: Boolean, default: false },
    inputFocused: { type: Boolean, default: false }
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

    this.boundOnKeydown = this.onKeydown.bind(this)
    this.element.addEventListener('keydown', this.boundOnKeydown)

    this.boundOnFocus = this.onFocus.bind(this)
    this.element.addEventListener('focus', this.boundOnFocus)

    this.boundOnBlur = this.onBlur.bind(this)
    this.element.addEventListener('blur', this.boundOnBlur)

    this.boundDocumentClick = this.onDocumentClick.bind(this)
    document.addEventListener('click', this.boundDocumentClick)
  }

  disconnect () {
    this.abort()

    delete this.lastApiResults

    if (this.parsedItems) {
      delete this.parsedItems
    }

    if (this.boundOnKeydown) {
      this.element.removeEventListener('keydown', this.boundOnKeydown)
      delete this.boundOnKeydown
    }

    if (this.boundOnInput) {
      this.element.removeEventListener('input', this.boundOnInput)
      delete this.boundOnInput
    }

    if (this.boundOnBlur) {
      this.element.removeEventListener('blur', this.boundOnBlur)
      delete this.boundOnBlur
    }

    if (this.boundOnFocus) {
      this.element.removeEventListener('focus', this.boundOnFocus)
      delete this.boundOnFocus
    }

    if (this.boundDocumentClick) {
      document.removeEventListener('click', this.boundDocumentClick)
      delete this.boundDocumentClick
    }

    this.removeDropdown()
  }

  onKeydown (e) {
    if (!this.autocompleteDropdown) return

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
      case 'Enter':
        e.preventDefault()
        this.handleAutocompleteActive('select')
        break
    }
  }

  setValue (value) {
    this.element.value = value
    this.element.dispatchEvent(new Event('change'))
    this.removeDropdown()
  }

  handleAutocompleteActive (action) {
    if (!this.autocompleteDropdown) return

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

  onBlur (_e) {
    this.inputFocusedValue = false
  }

  onFocus (_e) {
    this.inputFocusedValue = true
    this.loadOrSetItems(this.element.value)
  }

  abort () {
    if (this.abortController) {
      this.abortController.abort()
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
  }

  onDocumentClick (e) {
    const validTarget = e.target.closest('.f-input-autocomplete-dropdown .dropdown-item')

    if (validTarget && validTarget.closest('.f-input-autocomplete-dropdown') === this.autocompleteDropdown) {
      this.setValue(e.target.innerText)
    } else if (e.target !== this.element && this.autocompleteDropdown) {
      this.removeDropdown()
    }
  }

  onDropdownMouseenter () {
    this.dropdownHoverValue = true
  }

  onDropdownMouseleave () {
    this.dropdownHoverValue = false
  }

  addDropdown (html) {
    this.autocompleteDropdown = document.importNode(window.Folio.Input.Autocomplete.TEMPLATE.content.children[0], true)
    this.autocompleteDropdown.querySelector('.f-input-autocomplete-dropdown__menu').innerHTML = html
    this.autocompleteDropdown.style.width = `${this.element.offsetWidth}px`

    document.body.appendChild(this.autocompleteDropdown)

    this.boundDropdownMouseenter = this.onDropdownMouseenter.bind(this)
    this.autocompleteDropdown.addEventListener('mouseenter', this.boundDropdownMouseenter)

    this.boundDropdownMouseleave = this.onDropdownMouseleave.bind(this)
    this.autocompleteDropdown.addEventListener('mouseleave', this.boundDropdownMouseleave)

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
  }

  removeDropdownUnlessActive () {
    if (this.inputFocusedValue || this.dropdownHoverValue) return
    if (!this.autocompleteDropdown) return
    this.removeDropdown()
  }

  removeDropdown () {
    this.dropdownHoverValue = false

    if (this.floatingUiCleanup) {
      this.floatingUiCleanup()
      delete this.floatingUiCleanup
    }

    if (this.autocompleteDropdown) {
      if (this.boundDropdownMouseenter) {
        this.autocompleteDropdown.removeEventListener('mouseenter', this.boundDropdownMouseenter)
        delete this.boundDropdownMouseenter
      }

      if (this.boundDropdownMouseleave) {
        this.autocompleteDropdown.removeEventListener('mouseleave', this.boundDropdownMouseleave)
        delete this.boundDropdownMouseleave
      }

      this.autocompleteDropdown.remove()
      delete this.autocompleteDropdown
    }
  }

  setAutocompleteItems (items) {
    this.removeDropdown()

    if (items.length) {
      let html = ''

      items.forEach((item, index) => {
        if (index > 9) return
        html += `<li><span class="dropdown-item cursor-pointer d-block${index === 0 ? ' active' : ''}">${item}</span></li>`
      })

      this.addDropdown(html)
    }
  }

  dropdownHoverValueChanged (to, from) {
    if (typeof from === 'undefined') return
    if (to) return
    if (to === from) return
    this.removeDropdownUnlessActive()
  }

  inputFocusedValueChanged (to, from) {
    if (typeof from === 'undefined') return
    if (to) return
    if (to === from) return
    this.removeDropdownUnlessActive()
  }
})
