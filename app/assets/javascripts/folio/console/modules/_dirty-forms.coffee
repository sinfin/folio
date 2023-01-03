handled = false

handler = ($form) ->
  return if handled
  handled = true
  beforeunload = -> 'Changes you made may not be saved.'
  $('.f-c-form-footer').addClass('f-c-form-footer--dirty')
  $(window).on 'beforeunload', beforeunload
  $form.on 'submit', -> $(window).off('beforeunload')
  $form.off 'change.folioDirtyForms single-nested-change.folioDirtyForms'

$('.simple_form')
  .filter(-> @className.match(/(new_|edit_)/) or @className.indexOf('f-c-with-aside') isnt -1)
  .not('.f-c-simple-form-with-atoms')
  .on 'change.folioDirtyForms single-nested-change.folioDirtyForms', (e) ->
    return if $(e.target).hasClass('f-c-dont-set-dirty-forms')
    handler($(this))

$('.f-c-dirty-simple-form')
  .on 'change.folioDirtyForms single-nested-change.folioDirtyForms', (e) ->
    return if $(e.target).hasClass('f-c-dont-set-dirty-forms')
    handler($(this))

$('.f-c-simple-form-with-atoms__form')
  .on 'change.folioDirtyForms single-nested-change.folioDirtyForms', (e) ->
    return if $(e.target).hasClass('f-c-dont-set-dirty-forms')
    handler($(this).closest('form'))

receiveMessage = (e) ->
  return if e.origin isnt window.origin
  switch e.data.type
    when 'setFormAsDirty' then handler($('.f-c-simple-form-with-atoms'))

window.addEventListener('message', receiveMessage, false)
