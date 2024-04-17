//= require tom-select.complete
//= require folio/i18n

window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.Multiselect = {}

window.Folio.Input.Multiselect.I18n = {
  cs: {
    remove: 'Odebrat',
    placeholder: 'Přidat ...'
  },
  en: {
    remove: 'Remove',
    placeholder: 'Add ...'
  }
}

window.Folio.Input.Multiselect.removeIconHtml = () => {
  if (!window.Folio.Input.Multiselect.savedRemoveIconHtml) {
    const iconOptions = {
      class: "'f-input-multiselect__delete-icon",
      height: 16
    }

    window.Folio.Input.Multiselect.savedRemoveIconHtml = window.Folio.Ui.Icon.create('delete', iconOptions).outerHTML
  }

  return window.Folio.Input.Multiselect.savedRemoveIconHtml
}

window.Folio.Input.Multiselect.sort = (input) => {
  const value = input.tomselect.getValue()

  if (!value || value.length < 2) return

  const items = input.tomselect.control.querySelectorAll('.item')
  const itemsArray = Array.from(items)

  itemsArray.sort((a, b) => {
    if (a.dataset.optionIndex && b.dataset.optionIndex) {
      return parseInt(a.dataset.optionIndex) - parseInt(b.dataset.optionIndex)
    } else {
      return 0
    }
  })

  const sortedValues = itemsArray.map((item) => item.dataset.value)

  input.tomselect.setValue(sortedValues, true)
}

window.Folio.Input.Multiselect.renderItem = (data, escape) => (
  `<div data-option-index="${data.$option.dataset.index}">${escape(data.text)}</div>`
)

window.Folio.Input.Multiselect.onChange = (input, value) => {
  window.Folio.Input.Multiselect.sort(input)
}

window.Folio.Input.Multiselect.bind = (input) => {
  const tomselect = new window.TomSelect(input, {
    placeholder: window.Folio.i18n(window.Folio.Input.Multiselect.I18n, 'placeholder'),
    plugins: {
      dropdown_input: true,
      remove_button: {
        title: window.Folio.i18n(window.Folio.Input.Multiselect.I18n, 'remove'),
        label: window.Folio.Input.Multiselect.removeIconHtml()
      }
    },
    render: {
      item: window.Folio.Input.Multiselect.renderItem
    }
  })

  window.Folio.Input.Multiselect.sort(input)

  tomselect.on('change', (value) => {
    window.Folio.Input.Multiselect.onChange(input, value)
  })

  return tomselect
}

window.Folio.Input.Multiselect.unbind = (input) => {
  if (input.tomselect) {
    input.tomselect.off('change')
    input.tomselect.destroy()
    delete input.tomselect
  }
}

window.Folio.Stimulus.register('f-input-multiselect', class extends window.Stimulus.Controller {
  connect () {
    window.Folio.Input.Multiselect.bind(this.element)
  }

  disconnect () {
    window.Folio.Input.Multiselect.unbind(this.element)
  }
})
