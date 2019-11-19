$ ->
  $('.f-c-index-filters__autocomplete-input').each ->
    $input = $(this)

    # Don't autosubmit form
    $input.on 'change', (e) -> e.stopPropagation()

    $input.autocomplete
      minLength: 2
      source: (request, response) ->
        $.ajax
          url: $input.data('url')
          dataType: "json"
          data:
            q: request.term
            controller: $input.data('controller')
          success: (data) ->
            response(data.data)

      select: (e, ui) ->
        setTimeout (-> $input.closest('[data-auto-submit]').submit()), 0
