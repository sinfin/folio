window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.Index = window.FolioConsole.Index || {}
window.FolioConsole.Index.Filters = {}

window.FolioConsole.Index.Filters.bindAutocompletes = ($input, className) => {
  if (!className) {
    className = 'f-c-index-filters__autocomplete-input'
    // Don't autosubmit form
    $input.on('change', function (e) {
      return e.stopPropagation()
    })
  }

  $input.addClass(`${className}--bound`).autocomplete({
    minLength: 0,
    select: function (e, ui) {
      return setTimeout(function () {
        return $input.closest('[data-auto-submit]').submit()
      }, 0)
    },
    source: function (request, response) {
      return $.ajax({
        url: $input.data('url'),
        dataType: 'json',
        data: {
          q: request.term,
          controller: $input.data('controller')
        },
        success: function (data) {
          return response(data.data.map((el) => {
            return String(el)
          }))
        }
      })
    }
  }).on('focus.indexFiltersAutocomplete', function () {
    return $input.autocomplete('search', $input.val())
  })
}

window.FolioConsole.Index.Filters.unbindAutocompletes = function ($input) {
  if ($input.hasClass('f-c-index-filters__autocomplete-input--bound')) {
    return $input.removeClass('f-c-index-filters__autocomplete-input--bound').off('focus.indexFiltersAutocomplete').autocomplete('destroy')
  }
}

window.FolioConsole.Index.Filters.cleanSubmit = ($form) => {
  const params = new URLSearchParams()

  $form.serializeArray().forEach((hash) => {
    if (hash.value) {
      params.set(hash.name, hash.value)
    }
  })

  let url = $form.prop('action')
  const data = params.toString()

  if (data !== '') {
    const joiner = url.indexOf("?") === -1 ? "?" : "&"
    url = `${url}${joiner}${data}`
  }

  window.location.href = url
}

window.FolioConsole.Index.Filters.bind = () => {
  $('.f-c-index-filters__autocomplete-input').each((i, el) => {
    window.FolioConsole.Index.Filters.bindAutocompletes($(el), 'f-c-index-filters__autocomplete-input')
  })

  $('.f-c-index-filters__toggle').on('click', (e) => {
    e.preventDefault()
    $(e.currentTarget)
      .closest('.f-c-index-filters')
      .toggleClass('f-c-index-filters--expanded')
  })

  $('.f-c-index-filters__reset-input').on('click', (e) => {
    e.preventDefault()
    const $button = $(e.currentTarget)
    $button.closest('.input-group').find('.form-control').val('')
    $button.closest('form').submit()
  })

  $('.f-c-index-filters').on('submit', (e) => {
    e.preventDefault()
    window.FolioConsole.Index.Filters.cleanSubmit($(e.currentTarget))
  })

  $('.f-c-index-filters__text-autocomplete-input').each((i, el) => {
    window.FolioConsole.Index.Filters.bindAutocompletes($(el), 'f-c-index-filters__text-autocomplete-input')
  })
}

$(window.FolioConsole.Index.Filters.bind)
