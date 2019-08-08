$(document).on 'click', '.f-c-simple-form-with-atoms__form-overlay', (e) ->
  e.preventDefault()
  $form = $(this).closest('.f-c-simple-form-with-atoms__form')

  if $form.hasClass('f-c-simple-form-with-atoms__form--atoms')
    window.postMessage({ type: 'closeForm' }, window.origin)
  else
    $form.removeClass('f-c-simple-form-with-atoms__form--active')
