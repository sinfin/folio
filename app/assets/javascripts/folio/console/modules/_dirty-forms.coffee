$('.simple_form')
  .filter(-> @className.match(/(new_|edit_)/))
  .one 'change', ->
    beforeunload = -> 'Changes you made may not be saved.'

    $(window).on 'beforeunload', beforeunload
    $(this).on 'submit', -> $(window).off('beforeunload')
