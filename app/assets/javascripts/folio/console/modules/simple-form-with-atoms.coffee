$(document)
  .on 'click', '.f-c-simple-form-with-atoms__overlay-dismiss', (e) ->
    e.preventDefault()
    window.postMessage({ type: 'closeForm' }, window.origin)

  .on 'click', '.f-c-simple-form-with-atoms__form-toggle, .f-c-simple-form-with-atoms__title--clickable', (e) ->
    e.preventDefault()
    $('.f-c-simple-form-with-atoms').toggleClass('f-c-simple-form-with-atoms--expanded-form')

receiveMessage = (e) ->
  return if e.origin isnt window.origin
  switch e.data.type
    when 'setHeight' then $('.f-c-simple-form-with-atoms__iframe').css('min-height', e.data.height)

window.addEventListener('message', receiveMessage, false)
