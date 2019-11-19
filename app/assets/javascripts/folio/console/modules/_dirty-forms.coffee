handled = false

handler = ->
  return if handled
  handled = true
  beforeunload = -> 'Changes you made may not be saved.'
  $('.f-c-form-footer').addClass('f-c-form-footer--dirty')
  $(window).on 'beforeunload', beforeunload
  $form = $(this)
  $form = $form.closest('form') unless $form.is('form')
  $form.on 'submit', -> $(window).off('beforeunload')

$('.simple_form')
  .filter(-> @className.match(/(new_|edit_)/))
  .not('.f-c-simple-form-with-atoms')
  .one 'change', handler

$('.f-c-simple-form-with-atoms__form')
  .one 'change', handler

receiveMessage = (e) ->
  return if e.origin isnt window.origin
  switch e.data.type
    when 'setFormAsDirty' then handler()

window.addEventListener('message', receiveMessage, false)
