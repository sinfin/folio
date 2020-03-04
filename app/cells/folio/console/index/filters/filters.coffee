window.folioConsoleBindIndexFiltersAutocomplete = ($input) ->
  # Don't autosubmit form
  $input.on 'change', (e) -> e.stopPropagation()

  $input
    .addClass('f-c-index-filters__autocomplete-input--bound')
    .autocomplete
      minLength: 0
      select: (e, ui) ->
        setTimeout (-> $input.closest('[data-auto-submit]').submit()), 0
      source: (request, response) ->
        $.ajax
          url: $input.data('url')
          dataType: "json"
          data:
            q: request.term
            controller: $input.data('controller')
          success: (data) ->
            response(data.data)
    .on 'focus.indexFiltersAutocomplete', ->
      $input.autocomplete('search', $input.val())

window.folioConsoleUnbindIndexFiltersAutocomplete = ($input) ->
  if $input.hasClass('f-c-index-filters__autocomplete-input--bound')
    $input
      .removeClass('f-c-index-filters__autocomplete-input--bound')
      .off('focus.indexFiltersAutocomplete')
      .autocomplete('destroy')

$ ->
  $('.f-c-index-filters__autocomplete-input').each ->
    window.folioConsoleBindIndexFiltersAutocomplete($(this))
