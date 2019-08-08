$('.simple_form')
  .filter(-> @className.match(/(new_|edit_|f-c-simple-form-with-atoms)/))
  .one 'change', ->
    beforeunload = -> 'Changes you made may not be saved.'
    $('.f-c-form-footer').addClass('f-c-form-footer--dirty')

    $(window).on 'beforeunload', beforeunload
    $(this).on 'submit', -> $(window).off('beforeunload')
