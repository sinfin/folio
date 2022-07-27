//= require folio/input/_framework

window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.CollectionRemoteSelect = {}

window.Folio.Input.CollectionRemoteSelect.SELECTOR = '.f-input--collection-remote-select'

window.Folio.Input.CollectionRemoteSelect.bind = (input) => {
  const $input = $(input)

  $input.select2({
    width: '100%',
    language: document.documentElement.lang,
    allowClear: true,
    placeholder: {
      id: '',
      text: $input.data('placeholder')
    },
    ajax: {
      url: $input.data('url'),
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
  })
}

window.Folio.Input.CollectionRemoteSelect.unbind = (input) => {
  $(input).select2('destroy')
}

window.Folio.Input.framework(window.Folio.Input.CollectionRemoteSelect)
