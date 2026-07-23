window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.CollectionFilterable = {}

window.Folio.Input.CollectionFilterable.bind = (input, { includeBlank }) => {
  const $input = window.jQuery(input)

  $input.select2({
    width: '100%',
    allowClear: true,
    placeholder: { id: '', text: includeBlank },
    dropdownCssClass: $input.data('dropdown-class') || ''
  }).on('change.select2', (e) => {
    e.target.dispatchEvent(new window.CustomEvent('folioCustomChange', { bubbles: true }))
    e.target.dispatchEvent(new window.CustomEvent('folio_select2_change', { bubbles: true }))
  }).on('select2:open', (e) => {
    e.target.dispatchEvent(new window.CustomEvent('f-input-collection-filterable:open', { bubbles: true }))
  }).on('select2:close', (e) => {
    e.target.dispatchEvent(new window.CustomEvent('f-input-collection-filterable:close', { bubbles: true }))
  })
}

window.Folio.Input.CollectionFilterable.unbind = (input) => {
  window.jQuery(input).select2('destroy').off('change.select2').off('select2:open').off('select2:close')
}

window.Folio.Stimulus.register('f-input-collection-filterable', class extends window.Stimulus.Controller {
  static values = {
    includeBlank: { type: String, default: '' }
  }

  connect () {
    window.Folio.Input.CollectionFilterable.bind(this.element, {
      includeBlank: this.includeBlankValue
    })
  }

  disconnect () {
    window.Folio.Input.CollectionFilterable.unbind(this.element)
  }
})
