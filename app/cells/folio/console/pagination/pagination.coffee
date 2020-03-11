$(document).on 'click', '.f-c-pagination__page--gap', (e) ->
  e.preventDefault()
  $(this)
    .closest('.f-c-pagination')
    .addClass('f-c-pagination--expanded')
