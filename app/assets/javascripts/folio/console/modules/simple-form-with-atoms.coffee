$(document).on 'click', '.f-c-simple-form-with-atoms__form-overlay', (e) ->
  e.preventDefault()
  $(this)
    .closest('.f-c-simple-form-with-atoms__form')
    .removeClass('f-c-simple-form-with-atoms__form--active')
