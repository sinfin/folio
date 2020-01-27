handled = false

handler = ($form) ->
  return if handled
  handled = true
  beforeunload = -> 'Changes you made may not be saved.'
  $('.f-c-form-footer').addClass('f-c-form-footer--dirty')
  $(window).on 'beforeunload', beforeunload
  $form.on 'submit', -> $(window).off('beforeunload')

$('.simple_form')
  .filter(-> @className.match(/(new_|edit_)/) or @className.indexOf('f-c-with-aside') isnt -1)
  .not('.f-c-simple-form-with-atoms')
  .one 'change', ->
    handler($(this))

$('.f-c-dirty-simple-form')
  .one 'change', ->
    handler($(this))

$('.f-c-simple-form-with-atoms__form')
  .one 'change', ->
    handler($(this).closest('form'))

receiveMessage = (e) ->
  return if e.origin isnt window.origin
  switch e.data.type
    when 'setFormAsDirty' then handler($('.f-c-simple-form-with-atoms'))

window.addEventListener('message', receiveMessage, false)
