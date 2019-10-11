handler = ($form) ->
  beforeunload = -> 'Changes you made may not be saved.'
  $('.f-c-form-footer').addClass('f-c-form-footer--dirty')
  $(window).on 'beforeunload', beforeunload
  $(this).on 'submit', -> $(window).off('beforeunload')

$('.simple_form')
  .filter(-> @className.match(/(new_|edit_)/))
  .one 'change', -> handler($(this))

$('.f-c-simple-form-with-atoms')
  .one 'change', '.f-c-simple-form-with-atoms__form', ->
    handler($(this).closest('.f-c-simple-form-with-atoms'))
