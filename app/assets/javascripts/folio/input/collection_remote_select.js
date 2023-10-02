window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.CollectionRemoteSelect = {}

window.Folio.Input.CollectionRemoteSelect.bind = (input, { includeBlank, url }) => {
  const $input = $(input)

  $input.select2({
    width: '100%',
    language: document.documentElement.lang,
    allowClear: true,
    placeholder: { id: '', text: includeBlank },
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
          const $el = $(el)
          data[`by_atom_setting_${$el.data('atom-setting')}`] = $el.val()
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
    }
  }).on('change.select2', (e) => {
    e.target.dispatchEvent(new Event("folio_select2_change"))
  })
}

window.Folio.Input.CollectionRemoteSelect.unbind = (input) => {
  $(input).select2('destroy').off('change.select2')
}

window.Folio.Stimulus.register('f-input-collection-remote-select', class extends window.Stimulus.Controller {
  static values = {
    includeBlank: { type: String, default: "" },
    url: { type: String, default: "" }
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
