//= require folio/input/_framework
//= require folio/input/_ui_autocomplete

window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.RemoteAutocomplete = {}

window.Folio.Input.RemoteAutocomplete.SELECTOR = '.f-input--remote-autocomplete'

window.Folio.Input.RemoteAutocomplete.bind = (input) => {
  const $input = $(input)

  $input.autocomplete({
    minLength: 0,
    source: (request, response) => (
      $.ajax({
        url: $input.data('remote-autocomplete'),
        dataType: 'json',
        data: { q: request.term },
        success: (data) => response(data.data)
      })
    ),
    select: (e, ui) => {
      window.setTimeout(() => { $input.trigger('remoteAutocompleteDidSelect') }, 0)
      const $form = $input.closest('[data-auto-submit], .f-c-index-header__form')

      if ($form.length) {
        window.setTimeout(() => { $form.submit() }, 0)
      }
    }
  })

  $input.on('focus.folioInput', () => { $input.autocomplete('search') })
}

window.Folio.Input.RemoteAutocomplete.unbind = (input) => {
  const $input = $(input)

  $input
    .off('focus.folioInput')
    .autocomplete('destroy')
}

window.Folio.Input.framework(window.Folio.Input.RemoteAutocomplete)
