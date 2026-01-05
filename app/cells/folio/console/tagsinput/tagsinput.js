// converted via https://coffeescript.org/#try
// once you update it, remove it from package.json standard js ignored files

(function () {
  let dispose, init, makeItems, optionMapper

  optionMapper = function (str) {
    return {
      value: str
    }
  }

  makeItems = function (string) {
    if (string) {
      return string.split(', ').map(optionMapper)
    } else {
      return []
    }
  }

  init = function () {
    let $inputs
    $inputs = window.jQuery('.f-c-tagsinput')
    if ($inputs.length === 0) {
      return
    }
    return $inputs.each(function () {
      let $formGroup, $selectize, createOption
      $selectize = window.jQuery(this)
      $formGroup = $selectize.closest('.form-group')
      if ($formGroup.data('allow-create')) {
        createOption = optionMapper
      } else {
        createOption = false
      }
      return $selectize.selectize({
        dropdownParent: 'body',
        labelField: 'value',
        searchField: 'value',
        delimiter: ', ',
        plugins: ['remove_button'],
        create: createOption,
        createFilter: function (val) {
          let valid
          if (this.items.indexOf(val) !== -1) {
            return false
          }
          valid = true
          this.currentResults.items.forEach(function (item) {
            return valid = valid && item.id !== val
          })
          return valid
        },
        maxOptions: 50000,
        preload: 'focus',
        onChange: function (_value) {
          return $selectize.trigger('change')[0].dispatchEvent(new window.Event('change', {
            bubbles: true
          }))
        },
        load: function (q, callback) {
          return window.jQuery.ajax({
            url: '/console/api/tags/react_select',
            method: 'GET',
            data: {
              q,
              context: $selectize.data('context')
            },
            error: function () {
              return callback()
            },
            success: function (res) {
              return callback(res.data.map(optionMapper))
            }
          })
        },
        render: {
          option_create: function (data, escape) {
            return `<div class="create">
  ${window.FolioConsole.translations.add}
  <strong>${escape(data.input)}</strong>&hellip;
</div>`
          }
        }
      })
    })
  }

  dispose = function () {
    return window.jQuery('.f-c-tagsinput').each(function () {
      let ref
      return (ref = this.selectize) !== null ? ref.destroy() : void 0
    })
  }

  if (typeof Turbolinks !== 'undefined' && Turbolinks !== null) {
    window.jQuery(document).on('turbolinks:load', init).on('turbolinks:before-cache', dispose)
  } else {
    window.jQuery(init)
  }
})()
