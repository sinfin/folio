$(document).on 'click', '.f-c-simple-form-with-atoms__form-overlay', (e) ->
  e.preventDefault()
  $form = $(this).closest('.f-c-simple-form-with-atoms__form')

  if $form.hasClass('f-c-simple-form-with-atoms__form--atoms')
    window.postMessage({ type: 'closeForm' }, window.origin)
  else
    $form.removeClass('f-c-simple-form-with-atoms__form--active')

receiveMessage = (e) ->
  return if e.origin isnt window.origin
  switch e.data.type
    when 'setHeight' then $('.f-c-simple-form-with-atoms__iframe').css('min-height', e.data.height)

window.addEventListener('message', receiveMessage, false)
