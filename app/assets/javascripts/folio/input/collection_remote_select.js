window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.CollectionRemoteSelect = {}

window.Folio.Input.CollectionRemoteSelect.setValue = (input, value) => {
  const $input = $(input)
  $input.val(value).trigger('change')
}

window.Folio.Input.CollectionRemoteSelect.clearValue = (input) => {
  window.Folio.Input.CollectionRemoteSelect.setValue(input, null)
}

window.Folio.Input.CollectionRemoteSelect.bind = (input, { includeBlank, url }) => {
  const $input = $(input)

  $input.select2({
    width: '100%',
    language: document.documentElement.lang,
    allowClear: true,
    placeholder: { id: '', text: includeBlank },
    dropdownCssClass: $input.data('dropdown-class') || '',
    ajax: {
      url: url || $input.data('url'),
      dataType: 'JSON',
      minimumInputLength: 0,
      cache: false,
      data: (params) => {
        const data = {
          q: params.term,
          page: params.page || 1
        }

        $('.f-c-js-atoms-placement-setting').each((i, el) => {
          if (el.type === 'checkbox' || el.type === 'radio') {
            data[`by_atom_setting_${el.dataset.atomSetting}`] = el.checked
          } else {
            const $el = $(el)
            data[`by_atom_setting_${$el.data('atom-setting')}`] = $el.val()
          }
        })

        return data
      },
      processResults: (data, params) => {
        return {
          results: data.results,
          pagination: {
            more: data.meta && data.meta.pages > data.meta.page
          }
        }
      }
    },
    templateSelection: (data, container) => {
      const $el = $(data.element)

      Object.keys(data).forEach((key) => {
        if (key.indexOf('data-') === 0) {
          $el.attr(key, data[key])
        }
      })

      return data.text
    },
    templateResult: (data, container) => {
      if (!data.imageUrl) {
        return data.text
      }

      const $result = $(
        `<div class="select2-results__option-inner-wrap">
           <div class="select2-results__option-img-container">
              <img src="${data.imageUrl}"/>
           </div>
           <div>${data.text}</div>
         </div>`
      )

      return $result
    }
  }).on('change.select2', (e) => {
    e.target.dispatchEvent(new window.CustomEvent('folioCustomChange', { bubbles: true }))
    e.target.dispatchEvent(new window.CustomEvent('folio_select2_change', { bubbles: true }))
  }).on('select2:open', (e) => {
    e.target.dispatchEvent(new window.CustomEvent('f-input-collection-remote-select:open', { bubbles: true }))
  }).on('select2:close', (e) => {
    e.target.dispatchEvent(new window.CustomEvent('f-input-collection-remote-select:close', { bubbles: true }))
  })
}

window.Folio.Input.CollectionRemoteSelect.unbind = (input) => {
  $(input).select2('destroy').off('change.select2').off('select2:open').off('select2:close')
}

window.Folio.Stimulus.register('f-input-collection-remote-select', class extends window.Stimulus.Controller {
  static values = {
    includeBlank: { type: String, default: '' },
    url: { type: String, default: '' }
  }

  connect () {
    window.Folio.Input.CollectionRemoteSelect.bind(this.element, {
      includeBlank: this.includeBlankValue,
      url: this.urlValue
    })
  }

  disconnect () {
    window.Folio.Input.CollectionRemoteSelect.unbind(this.element)
  }
})
